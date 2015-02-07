package PGTools::MSearch::PostProcess::XTandem;


use strict;
use parent 'PGTools::MSearch::Base';



sub get_runnable {
  my $self = shift;

  my $ofile  = $self->ofile( '.csv' );
  my $ofile_processed = $self->ofile( '-processed.csv' );

}


1;
__END__
