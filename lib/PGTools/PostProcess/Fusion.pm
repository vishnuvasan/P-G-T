package PGTools::PostProcess::Fusion;

use strict;
use PGTools::Util;
use parent 'PGTools::PostProcess';
use IO::File;
use Text::CSV;
use Data::Dumper;


sub run {
  my $self = shift;

  my ( $input, $output ) = $self->files; 

  my $ofh = IO::File->new( $output, 'w' );
  my $csv = Text::CSV->new;

  my $re = qr/
    ^
    (?<gene_id_a>\w+):(?<gene_id_b>\w+)
    \s+
    (?<cancer_type>\S+)
    \s+
    \w+\{\w+\}:r\.
    (?<gene_start_a>\d+)
    _
    (?<gene_end_a>\d+)
    _
    \w+\{\w+\}:r\.
    (?<gene_start_b>\d+)
    _
    (?<gene_end_b>\d+)
    \s+
    strand:
    \w+=(?<gene_strand_a>[-+])
    ;
    \w+=(?<gene_strand_b>[-+])
  /x;


  $csv->print( $ofh, [ 
    qw/
      fusion_gene_id_1 
      fusion_gene_id_2
      cancer_type
      gene_region_1_start
      gene_region_1_end
      gene_region_2_start
      gene_region_2_end
      gene_strand_1
      gene_strand_2
    /
  ] );

  $ofh->write( "\n" );


  foreach_csv_row( $input => sub {


    my $row = shift;
    my $accession = $row->{protein} || $row->{Protein};

    # matches?
    if( $accession =~ /$re/ ) {

      # Keep a copy of current matches
      my %matches = %+;

      $csv->print( $ofh, [ @matches{
        qw/
          gene_id_a
          gene_id_b
          cancer_type
          gene_start_a
          gene_end_a
          gene_start_b
          gene_end_b
          gene_strand_a
          gene_strand_b
        / 
      } ] );

      $ofh->write( "\n" );
    }

    else {
      warn "No matches";
    }

  } );

}


1;
__END__
