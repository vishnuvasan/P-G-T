package PGTools::MSearch::PostProcess::MSGFDB;

use strict;
use parent 'PGTools::MSearch::Base';
use feature ':5.10';

sub get_runnable {
  sub { 
    say "MSGFDB post process about to run"; 
  };
}


1;
__END__
