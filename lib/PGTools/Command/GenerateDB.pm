package _Base;

use strict;

sub new {
  my $class = shift;
  my %options = @_;

  my $self = bless { %options }, $class;

  {
    no strict 'refs';

    while( my ( $key, $value) = each %options ) {
      *$key = sub {
        shift->{ $key };
      };
    }
  }

  $self;
}

package _Digest;

use strict;
use PGTools::Util;
use PGTools::Util::Translate;
use IO::File;
use base '_Base';

sub run {
  my $self = shift;
  my ( $file, $output ) = ( $self->input, $self->output );

  my $fasta     = PGTools::Util::Fasta->new_with_file( $file );
  my $ofh       = IO::File->new( $output, 'w' ) or die( "Cannot open $output for writing: $!" );
  my $tr        = PGTools::Util::Translate->new;

  $fasta->reset;

  while( $fasta->next ) {
    my $title = $fasta->title;
    my $sequence = $fasta->sequence_trimmed;
    my $strand = $title =~ /\+|plus/ ? 1 : -1;

    # set sequence
    $tr->set_sequence( $sequence );

    EVERY_FRAME: for my $frame ( 1 .. 3 ) {
      my @pieces = split /_/, $tr->translate( frame => $frame * $strand );

      EVERY_SEQUENCE_BW_STOP_CODONS: for my $piece ( @pieces ) {

        EVERY_DIGESTED_PIECE: for my $digested ( $self->digest( $piece ) ) {

          if( length( $digested) >= $self->min && length( $digested ) < $self->max ) {

            print $ofh '>'
              . $fasta->title 
              . " FRAME:$frame #$digested# "
              . $fasta->eol;

              print $ofh normalize( $digested ); 

          }
        }
      }
    }
  }

  $ofh->close;

}

sub digest {

  my $self = shift;
  my $string = shift;

  $string =~ s/\n//g;

  my @pieces;

  @pieces = $string =~ /(.+?[RK])(?!P)/g;

  @pieces;

}

package _Unique;


use strict;
use PGTools::Util;
use PGTools::Util::Translate;
use IO::File;
use base '_Base';

sub run {
  my $self = shift;
  my $digested = $self->input; 
  my $known    = $self->known; 
  my $unique   = $self->output; 

  my $ufh = IO::File->new( $unique, 'w' ) or die( "Can not open $unique for writing: $!" );
  my $dfa = PGTools::Util::Fasta->new_with_file( $digested );
  my $kfa = PGTools::Util::Fasta->new_with_file( $known );

  my %sequences = ();

  while(  $kfa->next ) {
    $sequences{ $kfa->sequence_trimmed } = 1;
  }

  my $exact_match = $self->part_match || 1;

  my $exists = sub {
    my $key = shift;
    if( $exact_match ) {
      return exists( $sequences{ $key } );
    } else {
      for ( keys %sequences ) {
        if( index( $_, $key ) >= 0 ) {
          return 1;
        }
      }
    }
  };

  while( $dfa->next ) {
    unless( $exists->( $dfa->sequence_trimmed ) ) {

      print $ufh '>'
        . $dfa->title 
        . $dfa->eol;

      print $ufh normalize( $dfa->sequence_trimmed ); 
    }
  }

  close $ufh;
}

package _Sieve;

use strict;
use PGTools::Util;
use PGTools::Util::Translate;
use IO::File;
use base '_Base';


sub run {

  my $self = shift;
  my $keep_duplicates = $self->keep_duplicates || 0;  

  my $digested = $self->input; 
  my $unique   = $self->output; 

  my $ufh = IO::File->new( $unique, 'w' ) or die( "Cant open $unique for writing: $!" );
  my $dfa = PGTools::Util::Fasta->new_with_file( $digested );

  my %sequences = ( );
  my %other = ( );

  while( $dfa->next ) {

    unless( $sequences{ $dfa->sequence } ) {
      $sequences{ $dfa->sequence } = $dfa->title;
    } else {

      $sequences{ $dfa->sequence } = 0 
        unless $keep_duplicates;

      $other{ $dfa->sequence } = $dfa->title;
    }
  }

  while( my ( $key, $value ) = each( %sequences ) ) {
    if( $value ) {
      print $ufh '>' . $value . $dfa->eol;
      print $ufh $key . $dfa->eol;
    }
  }

  close $ufh;

}



package PGTools::Command::GenerateDB;

=head1 NAME

PGTools::Command::GenerateDB

=head1 SYNOPSIS

  ./pgtools generatedb [OPTIONS] 

  [OPTIONS]
    -i    or    --input
    Input database 

    -k    or    --knowndb
    Known database

    -y    or    --digest-knowndb
    Digest known database before making comparisons

    -o    or    --output
    Location to place the output file

    -m    or    --min
    Minimum length of the digested sequence 

    -x    or    --max
    Maximum length of the digested sequence 

    -d    or    --keep-duplicates
    If two identical sequences are found after digestion, should we eliminate the 
    sequence entirely or keep one copy in the output database, by default both are
    eliminated, when this option is set, one of them is kept


    --full-match
    When this option is set, known database is digested and compared with input database. The digested
    sequences must exactly match the digested input database sequences


=head1 DESCRIPTION

=cut

use strict;
use PGTools::Util::Fasta;
use PGTools::Util;
use IO::File;

use parent 'PGTools::Command';

sub run {

  my $class   = shift; 

  my $options = $class->get_options( [
    'input|i=s', 'knowndb|k=s', 'full-match',
    'output|o=s', 'min|m=s', 'max|x=s',
    'digest-knowndb|y', 'keep-duplicates|d'
  ] );

  my ( $input, $frames, $known, $output, $full_match, $digest_knowndb ) = 
    @{ $options }{ qw/
      input frames 
      knowndb output 
      full-match digest-knowndb
    / };


  must_have "Input database ", $input;
  must_have "Known database ", $known;

  must_be_defined "Output database ", $output;

  # default set of frames
  $frames     ||= 3;
  $full_match ||= 0;


  # digest stuff
  _Digest->new( 
    input   => $input,
    output  => "$output.digested",
    min     => ( $options->{min} || 7 ),
    max     => ( $options->{max} || 36 )
  )->run;

  my $known_db = $known;
  if( $digest_knowndb ) {

    $known_db = "$output.known";

    # Digest the known database
    _Digest->new(
      input   => "$known",
      output  => $known_db, 
      min     => ( $options->{min} || 7 ),
      max     => ( $options->{max} || 36 )
    )->run;

  }

  # run unique
  _Unique->new(
    input       => "$output.digested",
    output      => "$output.unique",
    known       => $known_db, 
    part_match  => !$full_match 
  )->run;


  # sieve
  _Sieve->new(
    input => "$output.unique",
    output => $output,
    keep_duplicates => $options->{'keep-duplicates'} || 0
  )->run;

}

1;
__END__
