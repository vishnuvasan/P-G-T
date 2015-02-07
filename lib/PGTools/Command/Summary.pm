package PGTools::Command::Summary;

use strict;
use PGTools::Util;
use PGTools::Util::Path;
use PGTools::Util::Static;
use PGTools::Util::AccessionHelper;
use IO::File;
use Mojo::JSON;
use Text::CSV;
use Data::Dumper;
use List::Util qw/shuffle/;

use parent qw/
  PGTools::Command
  PGTools::SearchBase
/;

use IO::File;
use PGTools::Util::SummaryHelper;

=head1 NAME

PGTools::Command::Summary

=head1 SYNOPSIS

  ./pgtools summary <input_fasta_file> 

=head1 DESCRIPTION

This utilitiy generates summary for current proteome_run of PGTools, It
also generates visualization for merge/collate and group outputs

=cut

my $hold_directory;

sub to_run {
  my $file = shift;
  __PACKAGE__->get_runnables_with_prefix( 
    'PGTools::FDR', 
    $file, 
    { dont_cleanup => 1 }
  );
}


sub file_for {
  my $for = shift;
  my $db = shift;
  my $phase2 = shift;

  my $prefix = $phase2 ? 'genome_run' : 'proteome_run';

  my $file;
  $file = ( -e catfile( $hold_directory, $for ) )
    ? catfile( $hold_directory, $for ) 
    : ( catfile( $hold_directory, $prefix . '.' . $for  ) )
      ? catfile( $hold_directory, $prefix . '.' . $for )
      : undef;

  print "XXXX: FOR: $for DB: $db PHASE2: $phase2 \n";
  print "XXXX: FOUND: $file \n";

  if( ! -e $file and ! $phase2 ) {
    my $new_file = file_for( $for, $db, 1 );

    return $file unless -e $new_file;

    return $new_file;
  }

  return $file;

}

sub publish_venn_data {
  my ( $class, $data ) = @_;

  return 'null' unless $data;

  return Mojo::JSON->new->encode( $data );
}

sub generate_proteome_run_sumary {
  my $class = shift;
  my $config  = $class->config; 
  my $ifile   = $class->setup;
  my @files   = get_files( $ifile );
  my $venn_id = 1000;

  # lexical global
  $hold_directory = get_hold_directory( $ifile );

  my $data = { };
  my $handlers = {

    msearch     => sub {
      $data->{msearch} = msearch_data( \@files, \&to_run, 'default' );
    }, 

    full_merge  => sub {
      full_merge_data( $data, 'default', \&file_for )
    }, 

    group       => sub {
      if( -e file_for( 'group.csv') ) {
        my $file = ( file_for('group.csv') );
        my $cmd = qq{ perl -ne 'm/(Group (?:\\d+))/; print \$1 . "\\n"' $file | sort | uniq | wc -l};
        $data->{group} = `$cmd`; 


        $data->{group_file} = $file; 
        $data->{treemap} = $class->generate_treemap( $file, file_for( 'annotate.csv' ) );

      }
    }, 

    annotate    => sub {
      if( -e file_for( 'annotate.html' ) ) {
        my $file = file_for( 'annotate.html'); 
        $data->{annotate} = `grep '</tr>' $file | wc -l`;
        $data->{annotate_file} = $file;
      }
    }
  };

  # run summary collection
  $handlers->{$_}->() 
    for keys( %$handlers );

  my $msearch = '';

  for my $file ( @files ) {

    $msearch .= '<div class="panel panel-primary">'
      . '<div class="panel-heading">' . $file . '</div>'
      . '<div class="panel-body"> ';

    for my $run ( to_run( $file ) ) {
      $msearch .= msearch_entry_for( $file, $run, $data->{msearch}{default}{$file} );
    }

    $msearch .= '</div></div>'


  }

  my $html = get_header( data => $data ) . sprintf( "

    <div class='msearch-and-fdr pane-item show'>
      $msearch
    </div>

    <div class='merge pane-item hide'>

      <div class='number-display number-fdr display-large pull-left'>
        <div class='number-display-label'>
          Merge
        </div>
        <div class='number'>
           @{[ $data->{ merge }]} 
        </div>
        <div class='view-file'>
          <a href='file://@{[ $data->{merge_file}]}'>
            View File
          </a>
        </div>
      </div>

      <div class='full-width-image'>
        <img width='700' src='file://@{[ $data->{merge_image}]}' /> 
      </div>

    </div>

    <div class='group pane-item hide'>
      <div>
        @{[ $data->{treemap}{html} ]}
      </div>
      <div class='number-display number-fdr'>
        <div class='number-display-label'>
          Group
        </div>
        <div class='number'>
           @{[ $data->{ group }]} 
        </div>
        <div class='view-file'>
          <a href='file://@{[ $data->{ group_file }]}'>
            View File
          </a>
        </div>
      </div>
    </div>

    <div class='annotate pane-item hide'>
      <div class='number-display number-fdr display-large'>
        <div class='number-display-label'>
          Annotate
        </div>
        <div class='number'>
           @{[ $data->{ annotate }]} 
        </div>
        <div class='view-file'>
          <a href='file://@{[ $data->{ annotate_file }]}'>
            View File
          </a>
        </div>
      </div>
    </div>

    </div>
    </div>
    </div>
    </body>
    </html>
  " );


  $venn_id++;

  my $output = IO::File->new( 
    catfile( $hold_directory, 'summary.html' ), 
    'w' 
  ) or die( "Can't open file for writing: " . $! );

  $output->print( $html );
  $output->close;

  print "OK \n";

}

sub generate_genome_run_summary {
  my $class   = shift;
  my $config  = $class->config; 
  my $ifile   = $class->setup;
  my @files   = get_files( $ifile );
  my @databases = get_databases;

  my $css = PGTools::Util::Static->path_for( 
    css => 'bootstrap' 
  );

  my $js = PGTools::Util::Static->path_for(
    js => 'd3'
  );

  my $data = { };


  # msearch_data
  my $scratch_directory = scratch_directory_path;
  for my $database ( @databases ) {
    print "DOING: $database \n";

    # set the scratch directory path
    my $path = catfile( $scratch_directory, $ENV{ PGTOOLS_HOLD_PATH }, file_for_database( $database ) );

    {

      local $ENV{ PGTOOLS_SCRATCH_PATH } = $path;

      # $hold_directory = get_hold_directory( $ifile );
      $hold_directory =  @files > 1 ? $path : get_hold_directory( $ifile ); 

      for my $file ( @files ) {
        $data->{msearch}{ $database } = msearch_data( \@files, \&to_run, $database )->{ $database };
      }
  
      print "XXX: About to do merge data: $database \n";
      print "XXX: hold directory is: $hold_directory PATH IS: $path\n";
      full_merge_data( $data, $database, \&file_for );

      # publish extract right here
      # the bed files must most certainly be where
      # merged.BED are
      if( $database =~ /sixframe/i || $database =~ /6frame/ ) {
        my $merged_file = file_for( 'merged.BED', $database );

        unless( -e $merged_file ) {
          $merged_file = file_for( 'collate.', $database  );
        }
    
        print "FILE: $merged_file \n";

        # get extract data
        my @features = qw/
          novel.exons
          novel.genes
          outframe
          overlapping.exons
          overlapping.genes
        /;

        COLLECT_FEATURES: for my $feature ( @features ) {
          my $key = join '_', split /\./, $feature;
          my $filename = catfile( dirname( $merged_file ), file_without_extension( $merged_file ) .  "." . $feature . '.BED' );
          @{ $data->{features} }{ ( $key, $key . '_file' ) } = ( count_lines( $filename ), $filename ); 
        
        }
      }
    }
  }

  print Dumper $data;

  my $output_dir = catfile( scratch_directory_path, $ENV{ PGTOOLS_HOLD_PATH } ); 

  # make the path
  make_path $output_dir unless -d $output_dir;

  my $make_options = sub {
    my $with_db = shift;
    my $plot_count = 0;
    join " ", 
      map {
        $plot_count++;
        "--plot$plot_count=" . $_
      } 
      map {
        $with_db ? "$_:$data->{ $_ }{ bed_file }" : "$data->{ $_ }{ bed_file }"
      } 
      grep {
        -e $data->{ $_ }{ bed_file } 
      } @databases;
  };

  if( circos_is_configured ) {

    # circos here 
    my $options = $make_options->(); 

    # make the command
    my $command = " visualize --circos --output=$output_dir " . $options;

    print STDERR $command;

    # run circos
    eval {
      run_pgtool_command $command;
    };

    # generate circos
    $data->{circos_error} = $@ ? 'Error Generating Circos' : undef;
    $data->{circos_plot} = catfile( $output_dir, 'circos.png' );

  }

  # generate splatterd bar anyway
  my $splattered_bar = " visualize --splatteredbar --output=$output_dir " . $make_options->( 1 );
  run_pgtool_command $splattered_bar;

  my $options = $make_options->( 1 );

  my $bed_data = {
    map   { 
      $_ => +{ 
        file    => $data->{$_}{bed_file}, 
        count   => count_lines( $data->{$_}{bed_file} ) 
      } 
    }
    grep  { -e $data->{ $_ }{ bed_file } } 
    @databases
  };

  $data->{splattered_bar} = catfile( $output_dir, 'splattered_bar.png' );
  

  # now start generating the html file
  my $html = get_header( phase => 'Phase II', no_treemap => 1 );
  my $msearch = "";
  my $merge   = "";
  my $extract = "";

  print Dumper $bed_data;

  while( my ( $database, $value ) = each( %{ $data->{ msearch } }) ) {

    $msearch .= '<div class="panel panel-info">'
      . '<div class="panel-heading">' . $database. '</div>'
      . '<div class="panel-body"> ';

    # msearch output here
    while( my ( $file, $file_data) = each( %$value ) ) {

      $msearch .= '<div class="panel panel-primary">'
        . '<div class="panel-heading">' . $file . '</div>'
        . '<div class="panel-body"> ';


      my $path = catfile( $scratch_directory, 'phase2', file_for_database( $database ) );
      {

        local $ENV{ PGTOOLS_SCRATCH_PATH } = $path;

        for my $run ( to_run( $file ) ) {
          $msearch .= msearch_entry_for( $file, $run, $file_data ); 
        }

      }

      $msearch .= '</div></div>'

    }

    $msearch .= '</div></div>';

    print "DB: $database \n";
    if( $database =~ /sixframe/i || $database =~ /6frame/ ) {

      while( my ( $key, $value ) = each( %{ $data->{features} } )) {

        next if $key =~ /file/;

        $extract .= "
        <div class='number-display number-fdr display-large'>
          <div class='number-display-label'>
            $key
          </div>
          <div class='number'>
            $value
          </div>
          <div class='view-file'>
            <a href='file://@{[ $data->{features}{ $key .'_file' }]}'> View File </a> 
          </div>
        </div>
        "; 
      } 

    }
  }


  while( my ( $database, $value ) = each( %{ $data } ) ) {

    next if $database eq 'msearch';

    next unless ref $value eq 'HASH';

    $merge .= '<div class="panel panel-info">'
      . '<div class="panel-heading">' . $database . '</div>'
      . '<div class="panel-body"> ';

    # merge output here
    $merge .= "<div>

      <div class='number-display number-fdr display-large pull-left'>
        <div class='number-display-label'>
          Merge
        </div>
        <div class='number'>
           @{[ $value->{ merge }]} 
        </div>
        <div class='view-file'>
          <a href='file://@{[ $value->{merge_file}]}'>
            View File
          </a>
        </div>
      </div>

      <div class='full-width-image'>
        <img width='700' src='file://@{[ $value->{merge_image}]}' /> 
      </div>
    </div>
    ";

    $merge .= '</div> </div>'

  }

  my $bed_html = '';
  my @classes = qw/target decoy fdr/;
  while( my ( $database, $bd ) = each( %{ $bed_data } ) ) {
    my $cls = ( @classes )[ 0 ];
    $bed_html .= "
      <div class='number-display number-$cls number-display-small pull-left'>
        <div class='number-display-label'>
          $database
        </div>
        <div class='number'>
           @{[ $bd->{ count } + 1]} 
        </div>
        <div class='view-file'>
          <a href='file://@{[ $bd->{file}]}'>
            View File
          </a>
        </div>
      </div>
    ";
  }

  $html .= "

    <div class='msearch-and-fdr pane-item show'>
      $msearch
    </div>

    <div class='merge pane-item hide'>
      $merge
    </div>

    <div class='features pane-item hide'>
      $extract
    </div>

    <div class='chromosomal-distribution pane-item hide'>
      <div>
        @{[
           qq( <img src='file://$data->{splattered_bar}' /> ) 
        ]}
      </div>
      <div>
        $bed_html
      </div>
    </div>

    <div class='circos pane-item hide'>
      <div>
        @{[
          $data->{circos_error} || qq( <img width='1200' src='file://$data->{circos_plot}' /> ) 
        ]}
      </div>
      <div>
        $bed_html
      </div>
    </div>

    </div>
    </div>
    </body>
    </html>
  ";

  # circos output here

  my $summary_file = catfile( $output_dir, 'summary.html' );
  my $output = IO::File->new( $summary_file, 'w' ) or die( "Can't open file for writing: " . $! );
  $output->print( $html );
  $output->close;

  print $summary_file, "\n";
  print "OK \n";


}

sub run { 

  my $class = shift;

  my $options = $class->get_options( [ 'phase|p=s'] );
  my $label   = 'Summary: Phase ' . ( $options->{phase} || 1 );
  my $phase   = $ENV{ PGTOOLS_PHASE } = $options->{phase} || 1;

  if( $phase == 1 ) {
    $class->generate_proteome_run_sumary;
  }

  elsif( $phase == 2 ) {
    $class->generate_genome_run_summary;
  }

}



1;
