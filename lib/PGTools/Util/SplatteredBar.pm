package PGTools::Util::SplatteredBar;

use strict;
use PGTools::Util;
use Data::Dumper;
use File::Basename qw/dirname/;
use File::Spec::Functions;
use GD;

sub new {
  my ( $class, %options ) = @_;
  my %object = ();
  
  $object{ width }  = delete( $options{ width } ) || 1100;
  $object{ height } = delete( $options{ height } ) || 800;
  $object{ border } = delete( $options{ border } ) || 25; 

  my $self = bless \%object, $class;

  $self->initialize;

  $self;

}

{
  no strict 'refs';
  for my $attr ( qw'image width height border colors lengths data' ) {
    *$attr = sub {
      my ( $self, $val ) = @_;

      $self->{ $attr } = $val if $val;

      $self->{ $attr };
    };
  }
}


sub initialize {
  my $self = shift;

  my %colors;
  my $image = $self->image( 
    GD::Image->new( $self->width, $self->height )
  );

  $colors{white}   = $image->colorAllocate(255,255,255);	# first color is background
  $colors{gray}    = $image->colorAllocate(238,238,238);
  $colors{darkgray}= $image->colorAllocate(128,128,128);
  $colors{red}     = $image->colorAllocate(255,0,0);
  $colors{orange}  = $image->colorAllocate(255,136,0);
  $colors{yellow}  = $image->colorAllocate(221,221,0);
  $colors{green}   = $image->colorAllocate(0,170,0);
  $colors{cyan}    = $image->colorAllocate(0,187,187);
  $colors{blue}    = $image->colorAllocate(0,0,128);
  $colors{indigo}  = $image->colorAllocate(119,65,128);
  $colors{violet}  = $image->colorAllocate(238,130,238);
  $colors{magenta} = $image->colorAllocate(255,0,255);
  $colors{black}   = $image->colorAllocate(0,0,0);

  $self->colors( \%colors );

  $self->initialize_data;
}

sub initialize_data {
  my $self = shift; 

  my %_lengths = qw(
    1    249698942
    2    242508799
    3    198450956
    4    190424264
    5    181630948
    6    170805979
    7    159345973
    8    145138636
    9    138688728
    10    133797422
    11    135186938
    12    133275309
    13    114364328
    14    108136338
    15    102439437
    16    92211104
    17    83836422
    18    80373285
    19    58617616
    20    64444167
    21    46709983
    22    51857516
    X    156040895
    Y    57264655
  );

  $self->lengths( \%_lengths );

}

sub add_data {
  my $self = shift;
  my ( $bed_file, $database, $color ) = @_;

  $self->data( [ ] ) 
    unless $self->data;

  if( -e $bed_file ) {
    push @{ $self->data }, {
      file      => $bed_file,
      database  => $database,
      color     => $color
    };
  }
}


sub bar_start_y {
  my ( $self, $chromosome ) = @_;
  $self->bar_height - int( $self->lengths->{$chromosome} * $self->yscale ) + 40;   
}

sub publish {
  my $self = shift;
  my $output_file = shift;

  $self->read_all_data_files;

  my $number_of_bars  = scalar( keys( %{ $self->lengths } ) );
  my $border          = 70;
  my $bar_width       = ( $self->width - $border ) / $number_of_bars;
  my $ymax            = $self->height - ( $border / 2 );
  my $ymin            = $border / 2;
  my $bar_height      = ( $ymax - $ymin );
  my $yscale          = $bar_height / $self->longest;


  my ( $n, $x, $y, $x1, $y1, $x2, $y2 ) = ( 0, );

  for my $chromosome ( $self->sorted_chromosomes ) {
    my $y = $ymin + $bar_height - ( $self->lengths->{$chromosome} * $yscale );
    $x1 = ( $border / 2 ) + ( $n * $bar_width ); 
    $x2 = $x1 + ( $bar_width - 5 );

    # first rectangle
    print "CONTAINER: $x1, $y, $x2, " . $bar_height . " SCALE: " . $yscale . " \n";
    $self
      ->draw_rectangle( $x1, $y, $x2, $ymax, 'black', '' )
      ->draw_inner_rectangles( $chromosome, $x1, $x2, $ymax, $bar_height, $yscale )
      ->draw_text( $x1, $self->height - $self->border + 10, "chr$chromosome", 'black' );

    $n++;

  }

  $self
    ->draw_labels( 600, 50 )
    ->draw_text( 200,  50, 'Chromosomal Distribution of Proteogenomic Peptides',  'black')
    ->draw_scale( $ymin, $ymax, $self->longest );

  $self->save_image( $output_file );

}

sub draw_scale { 
  my ( $self, $ymin, $ymax, $longest ) = @_;

  $self->draw_line( 30, $ymin, 30, $ymax, 'black' );

  my ( $min, $max ) = ( 0, $longest / 1_000_000 );
  my $step =  ( $ymax - $ymin ) / ( $max - $min );
  my ( $init, $steps )  = ( 0, 20 );
  while( $init < $max ) {
    $self->draw_text( 5, $ymax, int( $init ), 'black' );
    $init += $steps;
    $ymax -= ( $step * $steps );
  }

}

sub draw_labels {
  my ( $self, $x, $y ) = @_;

  my $chr_width = 30;

  $self->draw_text( $x, $y, 'Legend', 'black', 0, 0 );

  $y += 20;

  for my $item ( @{ $self->data } ) {
    my $label = $item->{database};
    my $color = $item->{color};

    $self->draw_rectangle( $x, $y, $x + $chr_width, $y + 10, $color, $color ); 
    $self->draw_text( $x + $chr_width + 10, $y + 5, $label, 'black');

    $y += 40;
  }

  $self;

}

sub draw_inner_rectangles {
  my ( $self, $chromosome, $x1, $x2, $yc, $bar_height, $yscale ) = @_;

  # for each bed file
  for my $item ( @{ $self->data } )  {

    # for each entry in the bed file
    for my $entry ( @{ $item->{data} } ) {

      # are we doing this chromosome right now?
      if( $entry->{chromosome} eq "chr$chromosome" ) {
        my $color = $item->{color};
        my $y2 =  $yc - int( $entry->{start} * $yscale ) + 2;
        my $y1 =  $yc - int( $entry->{end} * $yscale );

        print "INNER: $x1, $y1, $x2, $y2 LOC: " . $entry->{start} / 1000000 . "\n";
        $self->draw_rectangle( $x1, $y1, $x2, $y2, $color, $color);
      }
    }
  }

  $self;

}


sub sorted_chromosomes {
  my $self = shift;
  sort by_chromosomes keys %{ $self->lengths }
}

sub by_chromosomes {
  if( $a =~ /^\d+$/ && $b =~ /^\d+$/ ) {
    $a <=> $b;
  } else {
    $a cmp $b;
  }
}


sub read_all_data_files {
  my $self = shift;
  for my $item ( @{ $self->data } ) {
    $item->{data} = read_bed_file $item->{file};
  }
}

sub yscale {
  my $self = shift;
  $self->bar_height / $self->longest;
}

sub longest {
  my $self = shift;
  my $lengths = $self->lengths;
  my $longest = 0;

  foreach my $chr ( keys %$lengths ) {
    if( $lengths->{$chr} > $longest ) {
      $longest = $lengths->{$chr};
    }
  }

  $longest;
}

sub line_width {
  my ( $self, $width ) = @_;

  $self->image->setThickness($width);

  $self;
}

sub color {
  my ( $self, $color ) = @_;
  $self->colors->{ $color };
}

sub make_color {
  my ( $self, $hex ) = @_;

  if ($hex =~ /#(\w{2})(\w{2})(\w{2})/) {
    my $r = hex($1);
    my $g = hex($2);
    my $b = hex($3);

    $self->colors->{ $hex } = $self->image->colorAllocate($r,$g,$b);
  }

}

sub draw_point {
  my ( $self, $x, $y, $color ) = @_;

  $self->make_color( $color ) 
    unless $self->color( $color );

  $self->image->setPixel($x, $y, $self->color( $color ) );

  $self;
}

sub draw_line {
  my ( $self, $x1, $y1, $x2, $y2, $color ) = @_;

  $self->make_color( $color ) 
    unless $self->color( $color );

  $self->image->line( $x1, $y1, $x2, $y2, $self->color( $color ) );

  $self;
}

sub draw_rectangle {
  my ( $self, $x1, $y1, $x2, $y2, $bcolor, $fcolor ) = @_;

  for ( $fcolor, $bcolor ) {
    $self->make_color( $_ ) 
      unless $self->color( $_ );
  }

  $self->image->filledRectangle($x1, $y1, $x2, $y2, $self->color( $fcolor ) );
  $self->image->rectangle($x1, $y1, $x2, $y2, $self->color( $bcolor ) );

  $self;

}

sub draw_text {
  my ( $self, $x, $y, $text, $color, $underline, $inverse, $angle ) = @_;
  my $image       = $self->image;
  my $pointsize   = 10;

  $y += int($pointsize/2);
  $angle = 0 unless ($angle);
  $angle = $angle/360 * 2 * 3.141592654;
  my @bounds;
  my $currentFont = catfile( dirname( __FILE__ ), '..', '..', 'static', 'fonts', 'open_sans.ttf' ); 
  my $white = $self->color( 'white' );

  if ($inverse) {
    if ($currentFont) {
       @bounds = $image->stringFT( $white, $currentFont, $pointsize, $angle, $x, $y, $text, {});
       my $width = $bounds[4] - $bounds[0];
       $image->filledRectangle($x, $y-$pointsize, $x+$width, $y, $self->color( $color ) ); 
       @bounds = $image->stringFT( $white, $currentFont, $pointsize, $angle, $x, $y, $text, {});
       }
    else {
       my $width = length($text) * 0.7*$pointsize;
       $image->filledRectangle($x, $y-$pointsize-1, $x+$width, $y-1, $self->color( $color ) );
       $y -= int(1.4*$pointsize);
       $image->string(gdSmallFont, $x, $y, $text, $self->color( 'white' ) );
       }
   }
   else {
      if ($currentFont) {
         @bounds = $image->stringFT( $self->color( $color ), $currentFont, $pointsize, $angle, $x, $y, $text, {});
      }
      else {
         $y -= int($pointsize);
         $image->string( gdSmallFont, $x, $y, $text, $self->color( $color ) );
         # $y += int(1.4*$pointsize);
         my $ybot = $y;
         my $width = length($text) * 0.7*$pointsize;
         @bounds = ($x, $ybot, $x+$width, $ybot, $x+$width, $y, $x, $y);
      }
    }

   if ($underline) {
      $y += 1;
      my $width = $bounds[4] - $bounds[0];
      my $xend = $x + $width;
      $image->line( $x, $y, $xend, $y, $self->color( $color ) );
   }

   $self;
}

sub save_image {

   my ( $self, $outfile, $transparent) = @_;

   my $image = $self->image;

   my %compression = (
    gif => "compress=>'LZW'",
    png => "compress=>'ZIP'",
    tiff => "compress=>'CCITT'",
    tif => "compress=>'ZIP'",
    pict => "",
    bmp => "",
   );

   $image->transparent( $self->color( 'white' ) ) if ($transparent);
   my $ext = substr($outfile, rindex($outfile,'.')+1);
   open(OUT, ">$outfile");
   binmode OUT;
   if( $ext eq 'png' ) { print OUT $image->png; }
   elsif( $ext eq 'gif' ) { print OUT $image->gif; }
   close(OUT);
   undef $image;
   return;
}

1;
__END__
