use strict;
use FindBin;
use lib "$FindBin::Bin/../../../lib";
use PGTools::Util;
use PGTools::Util::Fasta;
use IO::File;
use Data::Dumper;
use autodie;


# database
my $db = shift @ARGV;  

# input file
my $ip = shift @ARGV;

# overlap
my $overlap = shift @ARGV;

# output 
my $output = shift @ARGV;

must_exist "Database ", $db;
must_exist "Input file ", $ip;

my %sequences = ();
my $fa = PGTools::Util::Fasta->new_with_file( $db );
my $fh = IO::File->new( $output, 'w' ) or die( "Cant open $output for writing: $! ");

$fa->reset;

# read the entire database
while( $fa->next ) {
  $sequences{ $fa->title } = $fa->sequence_trimmed;
}

$overlap = $overlap =~ /^[0-9]+$/ ? $overlap : 1;


foreach_csv_row $ip => sub {
  my $row = shift;

  my $protein = $row->{Protein} || $row->{protein};
  my $peptide = $row->{peptide} || $row->{Peptide};
  my $full_sequence = $sequences->{ $protein };
  my ( $position ) = $protein =~ /POSITION:(\d+)/;

  my $start = index $peptide, $full_sequence; 
  my $end = $start + length( $peptide );

  # occurs after the range
  next if $position >= $end;

  # occurs before the range
  next if $position <= $start;

  my @full_range = $start .. $end;
  my $index_in_range = grep { $full_range == $position } 0 .. $#full_range;

  if( $index < $overlap || $index > ( $end - $overlap ) ) {
    next;
  }

  print $fh join( ',', @{ $row }{ qw/Peptide Protein xtandem omssa msgf/ } ) . "\n";

};

