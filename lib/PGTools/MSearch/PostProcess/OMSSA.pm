package PGTools::MSearch::PostProcess::OMSSA;

use strict;
use parent 'PGTools::MSearch::Base';

use PGTools::Util qw/
  extension
  file
  file_without_extension
  run_command
  run_pgtool_command
/;


sub get_runnable {

  my $self = shift;

  # Processed output file
  my $ofile = $self->ofile; 
  my $processed_ofile = $self->ofile( '-processed' );


  sub {
  };

}



1;
__END__
