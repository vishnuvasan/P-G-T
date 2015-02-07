package PGTools::Command::Visualize::Decoy;

use PGTools::Util;
use PGTools::Util::Path;
use PGTools::Util::SummaryHelper;
use PGTools::Configuration;
use Data::Dumper;
use Text::CSV;
use IO::File;
use File::Basename qw/dirname/;
use GD::Graph::bars;
use parent 'PGTools::Command';

sub run {

  my $class = shift;
  my $config = PGTools::Configuration->new->config;
  my $options = shift;
  my ( $target_file, $decoy_file, $name ) = @{ $options }{ qw/target_file decoy_file/ };

  my $output  = catfile( dirname( $target_file ), file_without_extension( file( $target_file ) ) . '.png' );
  my $bar     = GD::Graph::bars->new( 200, 200 );

  $bar->set(
    x_label => 'MSearch',
    y_label => 'Counts'
  );

  my $gdh = $bar->plot( 
    [
      [ 'Target', 'Decoy' ],
      [ count_lines( $target_file ) || 0, count_lines( $decoy_file ) || 0 ]
    ]
  );

  open my $ofh, '>', $output or die( "Can't open file: $output for writing: $!");
  binmode( $ofh );
  print $ofh $gdh->png;
  close( $ofh );


}



1;
__END__
