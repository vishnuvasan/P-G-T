package PGTools::Command::Visualize::SplatteredBar;

use strict;
use PGTools::Util;
use PGTools::Util::Path;
use PGTools::Util::SplatteredBar;
use File::Spec::Functions;
use parent 'PGTools::Command';

sub run {

  my $class = shift;
  my $config = PGTools::Configuration->new->config;
  my $options = shift;
  my $max_plots = 8;

  my $output_dir = $options->{output} || dirname( 
    ( grep { $_ } map { $options->{ "plot$_"} } ( 1 .. $max_plots ) )[ 0 ] || Cwd::getcwd() 
  ); 

  my $splattered_bar = PGTools::Util::SplatteredBar->new;
  my %map = (
    utr         => [ 'orange', 'UTRDB' ],
    splice      => [ 'black', 'SpliceDB' ],
    noncode     => [ 'red', 'NonCodeDB' ],
    pseudogene  => [ 'blue', 'PseudogeneDB' ],
    '6frame'    => [ 'violet', 'SixFrameDB' ],
    fusion      => [ 'indigo', 'FusionDB' ],
    mutation    => [ 'yellow', 'MutationDB' ]
  );


  # add all paths
  for my $plot_id (  1 .. $max_plots  ) {
    my $plot = $options->{"plot$plot_id"};
    my ( $database, $file_path ) = split /:/, $plot;

    if( exists( $map{ $database }) && -e $file_path ) {
      $splattered_bar->add_data( $file_path, ( $map{ $database }[ 1 ] || $database ), ( $map{ $database }[ 0 ] || 'red' ) );
    }
  }

  $splattered_bar->publish( catfile( $output_dir, 'splattered_bar.png' ) );

}


1;
__END__
