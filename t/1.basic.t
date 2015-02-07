use strict;
use Test::More; 

my @classes = qw/
  PGTools
  PGTools::Util
  PGTools::Command::Convert
  PGTools::Command::Help
  PGTools::Command::Decoy
  PGTools::::Command::Translate
  PGTools::Command::MSearch
  PGTools::Util::Fasta
  PGTools::Util::Translate
  PGTools::Configuration
  PGTools::Util::SplatteredBar
/;

use_ok $_ for @classes;

done_testing;
