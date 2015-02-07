package PGTools::Command::Extract;

use strict;
use IO::File;
use Getopt::Long;
use Data::Dumper;
use PGTools::Util::ExtractFeature;
use PGTools::Util;
use Carp qw/confess/;
use parent 'PGTools::Command';

=head1 NAME

PGTools::Command::Extract

=head1 SYNOPSIS

  ./pgtools extract [OPTIONS] 

  [OPTIONS]
    -b    or    --bed

    Input BED file


    -g    or    --gtf
    Input GTF file


    --novel-gene
    Detect novel genes

    --novel-exon
    Detect novel exons

    --overlapping-exon
    Detect overlapping exons

    --overlapping-gene
    Detect overlapping genes 

    --outframe
    Detect outframe 




=head1 DESCRIPTION

This utility detects novel and overlapping genes and exons. For this, we use
specially created databases which are created from the gtf files. Takes a BED 
file as input and examines each entry in the input bed file for the features
needed. For example, if  you have foo.BED and would like to find out all entries 
overlapping with known exons.

  pgtools extract --overlapping-exon --bed=foo.BED

would place a file 'overlappin.exon.foo.BED' in the same directory as bed file 
containing entries in the BED files that are overlapping with exons. All other 
extracts behave in an identical manner.

=cut


sub run {

  my $class = shift;

  my $options = $class->get_options( [
    'bed|b=s', 
    'novel-gene', 
    'novel-exon',
    'overlapping-gene',
    'overlapping-exon',
    'outframe',
    'debug'
  ]);

  my $bed = $options->{bed}; 

  must_have "BED File", $bed;

  # set to debug mode
  $ENV{ PGTOOLS_DEBUG } = 1 if $options->{debug};

  # feature extractor
  my $fe = PGTools::Util::ExtractFeature->new(
    bed_file     => $bed,
  )->prepare;

  # novel exon
  $fe->extract_novel_exon if $options->{'novel-exon'};

  # novel gene
  $fe->extract_novel_gene if $options->{'novel-gene'};

  # exon overlap
  $fe->extract_exon_overlap if $options->{'overlapping-exon'}; 

  # gene overlap
  $fe->extract_gene_overlap if $options->{'overlapping-gene'};

  # outframes
  $fe->extract_outframe if $options->{'outframe'};


  debug "Done";

}


"True";
__END__
