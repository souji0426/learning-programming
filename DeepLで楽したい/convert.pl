use strict;
use warnings;
use utf8;
use Encode;

open( my $input_fh, "<", "./input.txt" );
open( my $output_fh0, ">", "./output0.txt" );
while( my $line = <$input_fh> ) {
  $line =~ s/\. /\.\n/g;
  print $output_fh0 $line;
}

close $output_fh0;
close $input_fh;

open( my $input_fh0, "<", "./output0.txt" );
open( my $output_fh1, ">", "./output1.txt" );
while( my $line = <$input_fh0> ) {
  if ( $line !~ /\.\n/ ) {
    $line =~ s/\n//g;
    print $output_fh1 $line;
  } else {
    print $output_fh1 $line;
  }
}
close $output_fh1;
close $input_fh0;

open( my $input_fh1, "<", "./output1.txt" );
open( my $output_fh, ">", "./output.txt" );
while( my $line = <$input_fh1> ) {
  #いずれ設定ファイルとかでリスト化する
  if ( $line =~ /Dr.\n/ or
        $line =~ /Mr.\n/ or
        $line =~ /Ph.D.\n/ or
        $line =~ /O.K.\n/ ) {
    $line =~ s/\n//g;
    print $output_fh $line;
  } else {
    print $output_fh $line;
  }
}
close $output_fh;
close $input_fh1;

1;
