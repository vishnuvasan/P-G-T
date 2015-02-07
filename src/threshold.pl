use strict;
use IO::File;
use FindBin;
use lib "$FindBin::Bin/../lib";
use PGTools::Util::Fasta;
use PGTools::Util qw/
  normalize
/;
use Getopt::Long;
use Data::Dumper;


my $options = { };
GetOptions( 
  $options,
  'db=s',
  'blast=s',
  'threshold=s',
  'common=s',
  'unique=s',
);

my $digested = $options->{db};
my $blast = $options->{blast}; 
my $threshold = $options->{threshold} || 90;
my $common   = $options->{common} || 'COMMON.fa';
my $unique   = $options->{unique}  || 'UNIQUE.fa';

print $digested, "\n";
die "Digested fa can't be found "
  unless -e $digested;

die "Blast file can't be found "
  unless -e $blast;

my $cfh = IO::File->new( $common, 'w' );
my $ufh = IO::File->new( $unique, 'w' );
my $dfa = PGTools::Util::Fasta->new_with_file( $digested );
my $bfh = IO::File->new( $blast, 'r' ); 

my %blast = ( );
while( <$bfh> ) {
  my ( $id, $gi, $thr, @other ) = split /\s+/;
  if( !exists( $blast{ $id } ) || $blast{ $id } < $thr ) {
    $blast{ $id } = $thr; 
  }
}

print Dumper \%blast;
exit;

while( $dfa->next ) {
  my ( $id, @rest ) = split( /\W/, $dfa->title );

  if( $blast{ $id } >= $threshold ) {  
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


