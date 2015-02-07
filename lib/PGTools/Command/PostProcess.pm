package PGTools::Command::PostProcess;

use strict;
use parent 'PGTools::Command';
use PGTools::Util;

use PGTools::PostProcess::Fusion;

my @sub_commands = qw/ fusion /;


sub run {
  my $class = shift;


  my $options = $class->get_options( [
    @sub_commands, 'input|i=s', 'output|o=s'
  ] );


  # Get the commandline options
  must_have "Input file", $options->{input};
  must_be_defined "Output file", $options->{output};


  # Run, If possible
  COMMAND_CHECK: foreach my $command ( @sub_commands ) {

    if( exists $options->{ $command  } ) {

      my $klass = "PGTools::PostProcess::" . ucfirst( $command  );

      eval {
        $klass
          ->new( map { $_ => $options->{$_} } ( 'input', 'output' ) ) 
          ->run;
      }; 

      confess $@ if $@;

      # Drop out
      last COMMAND_CHECK;

    }

  }

}



1;
__END__
