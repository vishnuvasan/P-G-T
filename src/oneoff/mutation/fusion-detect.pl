
use strict;
use PGTools::Util;
use PGTools::Util::Fasta;
use IO::File;

my $input = shift @ARGV;
my $db    = shift @ARGV;

must_have "Input file must exist:", $input;
must_have "Database file must exist:", $input;

my $fh = IO::File->new( $input, 'r' ) or die( "Cant open $input for writing: $!" );
my $fa = PGTools::Util::Fasta->new_with_file( $db );
my $op = IO::File->new( "$input.output", 'w' ) or die( "Cant write output file for writing: $! " );
my %sequences = ();

$fa->reset;

# read the entire sequence into memory, so things become easier
$sequences{ $fa->title } = $fa->sequence_trimmed
  while $fa->next;

while( my $line = <$fh> ) {
  chomp $line;

  while( my ( $key, $value ) = each %sequences ) {
    # we have a match
    if( $value =~ /$line/g ) {

      print "MATCHES: $value - $line \n";

      # position of the match
      # length of subsequence
      # length of original sequence
      my ( $pos, $sub_len, $orig_len ) = ( pos( $value ), length( $line ), length( $value ) );

      #where was teh start of the match
      $pos -= $sub_len;

      print "POS: $pos, SUBLEN: $sub_len \n";

      # extract junction and junction position 
      my ( $junc, $junction_position ) = $key =~ /JUNC:(\w)\s+POSITION:(\d+)/;

      # 0 indexed, now
      $junction_position--;

      print "JUNC: $junc, JPOS: $junction_position \n";

      if( 
        # overlaps
        ( 
          $pos < $junction_position 
          && 
          ( $pos + $sub_len ) > $junction_position
        ) &&
        # make sure there atleast three peptides either end
        # including the juntion point ..X.. at the minimum
        (
          ( $junction_position - $pos ) >= 3 &&
          ( ( $pos + $sub_len ) - $junction_position >= 3 )

        )
      ) {
        print $op "$value\t$key\tMATCH:$pos\tJUNCTION:$junction_position\tLENGTH:$sub_len\n";
      }
    }
  }
}
