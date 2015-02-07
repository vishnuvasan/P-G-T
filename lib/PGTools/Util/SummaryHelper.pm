package PGTools::Util::SummaryHelper;

use strict;
use base 'Exporter';
use PGTools::Util;
use PGTools::Util::Path;
use File::Spec::Functions;
use File::Basename qw/dirname/;
use File::Path qw/make_path/;
use Data::Dumper;

our @EXPORT = qw/
  count_lines 
  get_files
  circos_is_configured
  get_header
  get_hold_directory
  msearch_data 
  full_merge_data
  file_for_database
  get_databases
  generate_json_from_group_file 
  generate_treemap 
  msearch_entry_for
/;

sub count_lines {
  my $file = shift;
  my ( $number ) = `wc -l $file` =~ /^\s*(\d+)/;

  int( $number ) - 1;
}

sub get_files {
  my $ifile = shift;
  my @files;

  if( -d $ifile ) {
    @files = <$ifile/*.mgf>;
  }

  else {
    @files = ( $ifile );
  }

  @files;
}

sub circos_is_configured {
  my $config = PGTools::Configuration->new->config;

  if( -d $config->{circos_path} ) {
    return 1;
  }

  warn "No Circos configured, Skipping circos plot...\n";

  0;

}


sub get_hold_directory {
  my $ifile = shift;
   $ENV{ PGTOOLS_CURRENT_RUN_DIRECTORY } || catfile( 
    scratch_directory_path, 
    file_without_extension( $ifile )
  );
}

sub msearch_data {
  my $files = shift;
  my $to_run = shift;
  my $db = shift; 
  my $data = { };

  for my $file ( @$files ) {


    for my $run ( $to_run->( $file ) ) {

      my $target = $run->ofile( '-target.csv');
      my $decoy  = $run->ofile( '-decoy.csv' );
      my $fdr = $run->ofile( '-filtered.csv' );
      my $vis = $run->ofile( '-target.png' );

      run_pgtool_command " visualize --decoy --target_file=$target --decoy_file=$decoy";
      @{ $data->{$db}{$file}{ $run->name } }{ qw/
        target decoy fdr target_file 
        decoy_file fdr_file graph
      /} = (
        count_lines( $target ),
        count_lines( $decoy ),
        count_lines( $fdr),
        $run->ofile( '-target.csv' ),
        $run->ofile( '-decoy.csv' ),
        $run->ofile( '-filtered.csv' ),
        $vis
      );

    }
  }

  $data;

}

sub full_merge_data {
  my (  $data, $db, $file_for ) = @_;
  my $file = $file_for->( 'pepmerge.csv', $db );

  unless( -e $file ) {
    $file = $file_for->( 'collate.csv', $db );
  }

  my $png_file = catfile( dirname( $file ), file_without_extension( file( $file ) ) . '.png' );

  my $d;
  if( $db eq 'default' ) {
    $d = $data;
  } else {
    $d = $data->{$db} = { };
  }

  print "File: $file \n";

  if( -e $file ) { 
    $d->{merge} = count_lines( $file ); 
    $d->{merge_file} = $file; 

    # generate visualization
    # PGTools::Visualize::Venn produces bad outputs
    # so removing this from here, We can extract the data here
    # and pass it on to summary file for us to generate Venn from 
    # d3
    run_pgtool_command ' visualize --venn --merge-file=' . $file;
    $d->{merge_image} = $png_file;
    $d->{venn_data} = venn_data( $file );
  }

  # must be a phase2 run
  # populate with .BED file link
  if( $d ne 'default' ) {
    
    for my $item ( qw/merged.BED collate.BED genome_run.collate.BED/ ) {
      if( -e catfile( dirname( $file ), $item ) ) {
        $d->{bed_file} = catfile( dirname( $file ), $item );
        last;
      }
    }
  }
}

sub file_for_database {
  my $config = PGTools::Configuration->new->config->{phase2_databases};
  my $database = shift;

  file_without_extension( file( $config->{ $database } ) );
}

sub get_databases {
  print Dumper \%ENV;
  if( $ENV{ PGTOOLS_SELECTED_DATABASES } ) {
    split /:/, $ENV{ PGTOOLS_SELECTED_DATABASES };
  }
}

sub venn_data {
  my $merge_file = shift;

  my @sets  = qw/omssa xtandem msgf/;

  my @areas = ();

  my %set_mapping = (
    omssa => 0b100,
    xtandem => 0b010,
    msgf => 0b001,
    omssa_xtandem => 0b110,
    omssa_msgf => 0b101,
    xtandem_msgf => 0b011,
    omssa_xtandem_msgf => 0b111
  );

  my ( %data, @venn_data ) = ();

  # process file
  foreach_csv_row $merge_file => sub {
    my $row = shift;
    my ( $o, $x, $m ) = @{ $row }{ qw/omssa xtandem msgf/ };
    my $digits = eval "0b". sprintf( '%d%d%d', map( int, ( $o, $x, $m ) ) );

    while( my ( $key, $val ) = each %set_mapping ) {
      if( $digits == $val ) {
        $data{ $key } += 1;
      }
    }
  };

  # save all data
  while( my ( $key, $val) = each %data ) {
    push @venn_data, {
      set   => [ split /_/, $key ],
      value => $val
    }
  }

  # return venn data
  {
    sets => \@sets,
    data => \@venn_data
  }



}

sub get_header {
  my %options = @_;
  my $phase = $options{ phase } || ' Phase I ';
  my $data = $options{ data };

  my $css = PGTools::Util::Static->path_for( 
    css => 'bootstrap' 
  );

  my $html = qq` 
    <!DOCTYPE html>
    <html>
      <head>
      <link rel='stylesheet' type='text/css' href='file://$css' />

      <style>
        .row-fluid { width: 99%; margin: auto auto; } 
        body { padding-top: 50px; }
        .sub-header { padding-bottom: 10px; border-bottom: 1px solid #eee; }
        .sidebar { display: none; }

        \@media (min-width: 768px) {
          .sidebar {
            position: fixed; top: 51px;
            bottom: 0; left: 0; z-index: 1000;
            display: block; padding: 20px; overflow-x: hidden;
            overflow-y: auto; 
            background-color: #f5f5f5; border-right: 1px solid #eee;
          }
        }

        .nav-sidebar {
          margin-right: -21px; /* 20px padding + 1px border */
          margin-bottom: 20px;
          margin-left: -20px;
        }
        .nav-sidebar > li > a {
          padding-right: 20px;
          padding-left: 20px;
        }
        .nav-sidebar > .active > a {
          color: #fff;
          background-color: #428bca;
        }

        .main {
          padding: 20px;
        }

        \@media (min-width: 768px) {
          .main {
            padding-right: 40px;
            padding-left: 40px;
          }
        }

      .main .page-header {
        margin-top: 0;
      }


      .placeholders {
        margin-bottom: 30px;
        text-align: center;
      }

      .placeholders h4 {
        margin-bottom: 0;
      }

      .placeholder {
        margin-bottom: 20px;
      }

      .placeholder img {
        display: inline-block;
        border-radius: 50%;
      }

      .hide { display: none; }
      .show { display: block; }

      </style>

      @{
        [
          map {
            sprintf( '<script src=\'file://%s\'> </script>', PGTools::Util::Static->path_for( js => $_ ) )
          } qw/jquery d3 venn summary /
        ]
      }

      <script>
        @{[ generate_venn()->{script} ]}
      </script>

      <script>
        var venn_data = { };
      </script>
   `;

   unless( $options{no_treemap} ) {
     $html .= "
        <script>
          @{[ $data->{treemap}{json} ]}
        </script>

        <script>
          @{[ $data->{treemap}{script} ]}
        </script>
     ";
    }


    $html .= qq`
      <style>
        body {
          font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
          margin: auto;
          position: relative;
          width: 100%; 
        }

        form {
          position: absolute;
          right: 10px;
          top: 10px;
        }

        .node {
          border: solid 1px white;
          font: 10px sans-serif;
          line-height: 12px;
          overflow: hidden;
          position: absolute;
          text-indent: 2px;
        }
      
      </style>
      <body>

      <div class="navbar navbar-inverse navbar-fixed-top" role="navigation">
        <div class="container-fluid">
          <div class="navbar-header">
            <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
              <span class="sr-only">Toggle navigation</span>
              <span class="icon-bar"></span>
              <span class="icon-bar"></span>
              <span class="icon-bar"></span>
            </button>
            <a class="navbar-brand" href="#"> PGTools Summary </a>
          </div>
        </div>
      </div>

      <div class="container-fluid">
          <div class="row">
            <div class="col-sm-3 col-md-2 sidebar">
              <ul class="nav nav-sidebar">
                @{[ nav_items() ]}
              </ul>
            </div>

        <div class="col-sm-9 col-sm-offset-3 col-md-10 col-md-offset-2 main">

    `;


    $html;

}

sub nav_items {
  if( $ENV{ PGTOOLS_PHASE } == 1 ) {
    as_nav( 
      qw/ msearch-and-fdr merge group annotate /
    )
  } else {
    as_nav(
      qw/ msearch-and-fdr merge features chromosomal-distribution circos/
    )
  }
}

sub as_nav {
  my $active = 0;
  my $html = '';

  for my $item ( @_ ) {
    $html .= '<li class="' . ( $active++ ? '' : 'active' ) . "\" data-item=\"$item\">" .
      "<a href='#'>" . join( ' ', map { uc } split( /-/, $item ) ) . '</a> </li>';
  }

  $html;

}

sub generate_venn {
  my $class = shift;

  my $script = '

    function _venn() {
      $( ".venn-plot" ).each( function( i, el) {

        var areas,
          id = $( el ).attr( "id" ).split( /-/ )[1];
          data = venn_data[ id ];

          console.log( venn_data );
          console.log( id );

          var sets = data.sets,
          d = data.data;

        areas = d.map( function( v ) {
          return {
            sets: v.set.map( function( s ) { return sets.indexOf( s ) } ),
            size: parseInt( v.value )
          };
        });

        var new_sets = sets.map( function( val, i ) { 
          console.log( val );
          console.log( "INDEX", i );
          return { 
            label: val,
            size: d3.sum( d.map( function( v ) {
              if( v.set.indexOf( val ) >= 0 ) {
                return parseInt( v.value )
              } else {
                return 0;
              }
            }))
          }; 
        } );

        new_sets = new_sets.filter( function( v ) { return v.size > 0 } );
        var venn_struct = venn.venn( new_sets, areas );
        var w = Math.min(450, document.documentElement.clientWidth-30);
        venn.drawD3Diagram( d3.select(".venn-plot"), venn_struct, w, 2*w/3);

      });


    }

    window.onload = function() {
      _venn();
    };

  ';


  return {
    script => $script
  };

}

sub _csv_file {
  my ( $file ) = @_;
  my $fh = IO::File->new( $file, 'r' ) or die( "Cannot open file: $file for reading");
  my $csv = Text::CSV->new( { binary => 1 });

  my $headings = $csv->getline( $fh );
  $csv->column_names( @$headings );

  my @data;
  while( my $row = $csv->getline_hr( $fh ) ) {
    push @data, $row;
  }

  $fh->close;

  ( $headings, \@data );
}

sub generate_json_from_group_file {
  my ( $class, $file, $annotate_file ) = @_;

  my ( %data, %annotate_data );
  my ( $headings, $data ) = _csv_file( $file );
  my ( $aheadings, $annotated ) = _csv_file( $annotate_file );


  for my $row ( @$annotated ) {
    $annotate_data{ $row->{ "Merge ID"} } = $row->{ "GeneSymbol" };
  }

  for my $row ( @$data ) {
    my $key = $row->{Group};
    my $rep = $row->{ 'Representitive-Unassigned' };

    unless( $data{ $key } ) {
      $data{ $key } = {
        size      => 1,
        name      => ( $rep ? PGTools::Util::AccessionHelper->id_from_accession( $row->{Protein} ) : '' ),
        children  => [ ]
      };
    } else {
      $data{ $key }{ size }++;
      $data{ $key }{ name } = $rep ? PGTools::Util::AccessionHelper->id_for_accession( $row->{Protein} ) : '';
      push @{ $data{ $key }{ children } }, PGTools::Util::AccessionHelper->id_for_accession( $row->{Protein} )
    }

  }

  'var data = ' . Mojo::JSON->new->encode( {
    name => 'Group',
    children => [
      map {
        my $name = $data{ $_ }{name};
        my $size = $data{ $_ }{ size };
        +{
          name => ( $annotate_data{ $name } || $name ) . "($size)",
          children => [
            { 
              name => ( $annotate_data{ $name } || $name ) . "($size)",
              size => $size 
            }
          ]
        }
      } keys %data
    ]

  } ) . ';';
}

sub generate_treemap {
  my $class = shift;
  my $group_file = shift;
  my $annotate_file = shift;

  my $json = $class->generate_json_from_group_file( $group_file, $annotate_file );

  my $script = '

window.onload = function() {
  

    var w = 1200 - 80,
    h = 700 - 180,
    x = d3.scale.linear().range([0, w]),
    y = d3.scale.linear().range([0, h]),
    color = d3.scale.category20c(),
    node, root;

  var treemap = d3.layout.treemap()
      .round(false)
      .size([w, h])
      .sticky(true)
      .value(function(d) { return d.size; });

    
  var svg = d3.select("#treemap").append("div")
      .attr("class", "chart")
      .style("width", w + "px")
      .style("height", h + "px")
    .append("svg:svg")
      .attr("width", w)
      .attr("height", h)
    .append("svg:g")
      .attr("transform", "translate(.5,.5)");

  node = root = data; 

  var nodes = treemap.nodes(root)
      .filter(function(d) { return !d.children; });

  var cell = svg.selectAll("g")
      .data(nodes)
    .enter().append("svg:g")
      .attr("class", "cell")
      .attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; })
      .on("click", function(d) { return zoom(node == d.parent ? root : d.parent); });

  cell.append("svg:rect")
      .attr("width", function(d) { return d.dx - 1; })
      .attr("height", function(d) { return d.dy - 1; })
      .style("fill", function(d) { return color(d.parent.name); });

  cell.append("svg:text")
      .attr("x", function(d) { return d.dx / 2; })
      .attr("y", function(d) { return d.dy / 2; })
      .attr("dy", ".18em")
      .attr("text-anchor", "middle")
      .text(function(d) { return d.name; })
      .style("opacity", function(d) { 
        d.w = 11 * d.name.length; 
        return d.dx - d.w > 2 ? 1 : 0
      });

  d3.select(window).on("click", function() { zoom(root); });

  d3.select("select").on("change", function() {
    treemap.value(this.value == "size" ? size : count).nodes(root);
    zoom(node);
  });

  function size(d) {
    return d.size;
  }

  function count(d) {
    return 1;
  }


function zoom(d) {
  var kx = w / d.dx, ky = h / d.dy;
  x.domain([d.x, d.x + d.dx]);
  y.domain([d.y, d.y + d.dy]);

  var t = svg.selectAll("g.cell").transition()
      .duration(d3.event.altKey ? 7500 : 750)
      .attr("transform", function(d) { return "translate(" + x(d.x) + "," + y(d.y) + ")"; });

  t.select("rect")
      .attr("width", function(d) { return kx * d.dx - 1; })
      .attr("height", function(d) { return ky * d.dy - 1; })

  t.select("text")
      .attr("x", function(d) { return kx * d.dx / 2; })
      .attr("y", function(d) { return ky * d.dy / 2; })
      .style("opacity", function(d) { return kx * d.dx > d.w ? 1 : 0; });

  node = d;
  d3.event.stopPropagation();

}

};

  ';

  my $html = '<div id="treemap"></div>';

  return {
    html => $html,
    json => $json,
    script => $script
  };

}

sub msearch_entry_for {
  my ( $file, $run, $data ) = @_;


  "
    <div class='pull-left panel panel-success'>
      <div class='panel-heading'>
        <span class='label label-success'> @{[ $run->name ]} </span>
      </div>
      <div class='panel-body'>

        <div class='number-display number-target'>
          <div class='number-display-label'>
            Target
          </div>
          <div class='number'>
             @{[ $data->{ $run->name }{ target }]} 
          </div>
          <div class='view-file'>
            <a href='file://@{[ $data->{$run->name}{target_file}]}'>
              View File
            </a>
          </div>
        </div>


        <div class='number-display number-decoy'>
          <div class='number-display-label'>
            Decoy
          </div>
          <div class='number'>
             @{[ $data->{ $run->name }{ decoy }]} 
          </div>
          <div class='view-file'>
            <a href='file://@{[ $data->{$run->name}{decoy_file}]}'>
              View File
            </a>
          </div>
        </div>

        <div class='number-display number-fdr'>
          <div class='number-display-label'>
            FDR 
          </div>
          <div class='number'>
             @{[ $data->{ $run->name }{ fdr }]} 
          </div>
          <div class='view-file'>
            <a href='file://@{[ $data->{$run->name}{fdr_file}]}'>
              View File
            </a>
          </div>
        </div>

        <div class='pull-left'>
          <img src='file://@{[ $data->{ $run->name }{ graph } ]}' />
        </div>

      </div>
    </div>
      ";

}

1;
__END__
