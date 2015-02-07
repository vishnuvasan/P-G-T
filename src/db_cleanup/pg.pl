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


my @remove_from_attr = qw/
  gene_status
  gene_type
  transcript_status
  transcript_name
  transcript_type
/;

while( $fa->next ) {
  my $title = $fa->title;

  $title =~ s/details:\([^)]+\)//g;

  my ( $att ) = $title =~ /attributes:\(([^)]+)\)/;

  my %attributes = map {
    my ( $key, $val ) = split /=/, $_;
    $key => $val;
  } split /;/, $att;

  # remove attributes
  delete $attributes{ $_ } for @remove_from_attr;

  # new attributes 
  my $new_att = join ';', map {
    "$_=$attributes{$_}"
  } keys %attributes;

  $title =~ s/attributes:\([^)]+\)/attributes:\($new_att\)/g;


  print $oh '>' .
      $title . ' ' . $fa->eol . $fa->sequence . $fa->eol;

}
