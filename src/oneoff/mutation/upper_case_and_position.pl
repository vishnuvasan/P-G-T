use strict;
use FindBin;
use lib "$FindBin::Bin/../../../lib";
use PGTools::Util;
use PGTools::Util::Fasta;
use PGTools::Util::Translate;
use IO::File;
use Data::Dumper;
use autodie;

my $input = shift @ARGV;
my $output = shift @ARGV;

my $fa = PGTools::Util::Fasta->new_with_file( $input );
my $fh = IO::File->new( $output, 'w' ) or die( "Cant open file for writing $!" );

$fa->reset;

while( $fa->next ) {
  my $seq = $fa->sequence_trimmed;

  $seq =~ /[a-z]/g;
  my $pos = pos( $seq );
  my $junc = substr( $seq, $pos-1, 1 );

  print $fh '>'
    . $fa->title . " JUNC:$junc POSITION:" . $pos . $fa->eol . uc( $seq ) . $fa->eol;

}
