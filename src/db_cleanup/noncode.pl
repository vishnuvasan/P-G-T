use strict;
use FindBin;
use lib "$FindBin::Bin/../../../lib";
use PGTools::Util;
use PGTools::Util::Fasta;
use IO::File;
use Data::Dumper;
use autodie;

my $input = shift @ARGV; 
my $output = shift @ARGV; 

must_have "Input file ", $input;
must_be_defined "Output file ", $output;

my $fa = PGTools::Util::Fasta->new_with_file( $input );
my $oh = IO::File->new( $output, 'w' ) or die( "Can't open file for writing" );

$fa->reset;

while( $fa->next ) {
  my $title = $fa->title;

  next if $title =~ /snoRNA/;

  $title =~ s/NULL\s+\|//g;


  print $oh '>' .
      $title . ' ' . $fa->eol . $fa->sequence . $fa->eol;

}

close $oh;

