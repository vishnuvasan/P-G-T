package PGTools::PostProcess;

use strict;
use PGTools::Util;


sub new {
  my $class = shift;
  my %options = @_;

  must_have "Input file", $options{ input };
  must_be_defined "Output file ", $options{ output };

  bless {
    map { $_ => $options{ $_ } } qw/ input output /
  }, $class;  

}

sub run {
  confess "Unimplemented";
}

sub files {
  my $self = shift;
  my @files = @{ $self }{ qw/ input output / };

  wantarray ? @files : \@files;

}


1;
__END__


