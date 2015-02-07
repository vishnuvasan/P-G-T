use strict;
use IO::File;
use PGTools::Util::Fasta;
use PGTools::Util qw/
  normalize
/;
use Getopt::Long;
use Data::Dumper;


my $options = { };
GetOptions( 
  $options,
  'part-match'
);

my $digested = shift @ARGV;
my $known    = shift @ARGV;
my $common   = shift( @ARGV) || 'COMMON.fa';
my $unique   = shift( @ARGV ) || 'UNIQUE.fa';

die "Digested fa can't be found "
  unless -e $digested;

die "Known fa can't be found "
  unless -e $known;

my $cfh = IO::File->new( $common, 'w' );
my $ufh = IO::File->new( $unique, 'w' );
my $dfa = PGTools::Util::Fasta->new_with_file( $digested );
my $kfa = PGTools::Util::Fasta->new_with_file( $known );


my $exact_match = !$options->{'part-match'}; 

my %sequences = ( );

while(  $kfa->next ) {
  $sequences{ $kfa->sequence_trimmed } = 1;
}

print Dumper $options;
print Dumper $exact_match;

my $exists = sub {
  my $key = shift;
  if( $exact_match ) {
    return exists( $sequences{ $key } );
  } else {
    for my $item ( keys %sequences ) {
      if( index( $item, $key ) >= 0 ) {
        return 1;
      }
    }

    return 0;
  }
};

while( $dfa->next ) {

  if( $exists->( $dfa->sequence_trimmed ) ) {
    print $cfh '>'
      . $dfa->title 
      . $dfa->eol;

    print $cfh normalize( $dfa->sequence_trimmed ); 

  }
  else {
    print $ufh '>'
      . $dfa->title 
      . $dfa->eol;

    print $ufh normalize( $dfa->sequence_trimmed ); 
  }

}

$cfh->close;
$ufh->close;


