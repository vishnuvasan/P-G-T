package PGTools::Command::FixOutput;

use strict;
use PGTools::Util::Fasta;
use PGTools::Util;
use PGTools::Util::Path;
use IO::File;
use Text::CSV;
use Data::Dumper;

use parent 'PGTools::Command';

=head1 NAME

PGTools::Command::FixOutput

=head1 SYNOPSIS

  ./pgtools fix_output [OPTIONS] 

  [OPTIONS]
    -d    or    --database
    Database the msearch was run against

    -i    or    --input
    Input CSV file, this needs to be either pepmerge file or collate output

    -l    or    --overlap
    In case output for mutation sequences, what must be the overlap between the 
    two sequences so the given entry is appended to the output file. Only applies
    when `full-match` is not been specified

    --full-match
    In case of non-mutation peptides, this option allows the given entry only if
    the pepmerge or collate sequence completely matches the sequence in the database.
    This applied by default to all outputs produced in `genome_run` for `pseudogene`,
    `utr` and `noncode` databases

    -o    or    --output
    The location where output files must be placed. This location must be writable by
    the user that executed the program, else the program will fail with an error


=head1 DESCRIPTION

FixOutput is a small utility that post-processes the output files from `PepMerge` in genome_run
to fix incorrect outputs that `msearch` currently unable to handle. There two modes for fix_output
the first one applies to mutation peptides, where two different sequences mutate at a given point.

In this case fix_output checks if there's a set amount of overlap, in case there is, the entry is pushed
into the output file, else the entry is disregarded.

In the second mode, fix_output exepects the pepmerge sequence to be identical to the one in the database,
else, the output is disregarded.

The output produced is identical in format to the input, This command filters out a few rows from the input
file based on conditions described above.

=cut


sub run {

  my $class   = shift; 

  my $options = $class->get_options( [
    'database|d=s', 'input|i=s', 'overlap|l=s', 'output|o=s', 
    'full-match'
  ]);

  my ( $db, $ip, $overlap, $output ) = @{ $options }{
    qw/ database input overlap output /
  };

  must_have "Database ", $db;
  must_have "Input file ", $ip;
  must_be_defined "Output file ", $output;

  my %sequences = ();
  my $fa  = PGTools::Util::Fasta->new_with_file( $db );
  my $fh  = IO::File->new( $output, 'w' ) or die( "Cant open $output for writing: $! ");
  my $csv = Text::CSV->new;

  $fa->reset;

  # read the entire database
  while( $fa->next ) {
    $sequences{ trim( $fa->title ) } = $fa->sequence_trimmed;
  }

  $overlap = $overlap =~ /^[0-9]+$/ ? $overlap : 1;

  my $overlap_match = sub {
    my ( $protein, $peptide ) = @_;

    my $full_sequence = $sequences{ $protein };
    my ( $position ) = $protein =~ /POSITION:(\d+)/;

    $position--;

    my $start = index $full_sequence, $peptide;
    my $end = $start + length( $peptide );

    print "$protein \n";
    print "original: $full_sequence \n";
    print "matched: $peptide \n";
    print "OVERLAP: $overlap START: $start END: $end POS: $position \n\n";

    # occurs after the range
    return 0 if $position >= $end;

    # occurs before the range
    return 0 if $position <= $start;

    my @full_range = $start .. $end;
    my $index = grep { $full_range[ $_ ] == $position } 0 .. $#full_range;

    print "FOUND: $index \n";

    # match overlaps
    if( 
      ( $position - $start ) >= $overlap && 
      ( $end - $position ) >= $overlap 
    ) {
      print "VALID \n\n";
      return 1;
    }

    return 0;

  };

  # print Dumper \%sequences;
  my $exact_match = sub {
    my ( $protein, $peptide ) = @_;
    # print "EXACT MATCH \n";
    # print "PROTEIN: $protein \n";
    # print "ORIGINAL: $sequences{ $protein } \n";
    # print "PEPTIDE: $peptide \n";

    $sequences{ $protein } eq $peptide;
  };

  my $filter = sub {
    my ( $protein, $peptide ) = @_;

    if( $options->{ 'full-match' } ) {
      return $exact_match->( $protein, $peptide )
    }

    else {
      return $overlap_match->( $protein, $peptide );
    }
  };

  my $write_into_csv = sub {
    my $row = shift;
    $csv->print( $fh, $row );
    $fh->write( "\n" );
  };



  my $is_columns_written = 0;

  foreach_csv_row $ip => sub {
    my $row = shift;
    my $cols = shift;

    print Dumper $row;

    # write columns
    if( ! $is_columns_written ) {
      $write_into_csv->( $cols );
      $is_columns_written = 1;
    }

    my $protein = trim(  $row->{Protein} || $row->{protein} );
    my $peptide = trim( $row->{Peptide} || $row->{peptide} );

    $write_into_csv->( [ @{ $row }{ @$cols } ] ) 
      if $filter->( $protein, $peptide );
  };

  # over and out charlie
  close $fh;

  # no rows produces, just output an empty file
  cp $ip, $output unless $is_columns_written;

}


1;
__END__
