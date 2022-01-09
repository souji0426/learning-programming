use strict;
use warnings;
use utf8;
use Encode;

#ピリオドをすべてピリオド＋改行に変換
#ただしピリオドが連続する場合は一旦別の文字列に変換しておく
open( my $input_fh, "<", "./input.txt" );
open( my $middle_fh0, ">", "./middle0.txt" );
while( my $line = <$input_fh> ) {
  $line =~ s/\. \. \. /hogehogehoge/g;
  $line =~ s/\. /\.\n/g;
  print $middle_fh0 $line;
}

close $middle_fh0;
close $input_fh;

#行末がピリオドでない行をくっつける
open( my $input_fh0, "<", "./middle0.txt" );
open( my $middle_fh1, ">", "./middle1.txt" );
while( my $line = <$input_fh0> ) {
  if ( $line !~ /\.\n/ ) {
    $line =~ s/\n//g;
    print $middle_fh1 $line;
  } else {
    print $middle_fh1 $line;
  }
}
close $middle_fh1;
close $input_fh0;

#文末以外で使用されているピリオドを元に戻す。
open( my $input_fh1, "<", "./middle1.txt" );
open( my $middle_fh2, ">", "./middle2.txt" );
while( my $line = <$input_fh1> ) {
  #いずれ設定ファイルとかでリスト化する
  if ( $line =~ /Dr\.\n/ or
        $line =~ /Mr\.\n/ or
        $line =~ /Ph\.\n/ or
        $line =~ /D\.\n/ or
        $line =~ /O\.K\.\n/ or
        $line =~ /i\.o\.\n/ ) {
    $line =~ s/\n/ /g;
    print $middle_fh2 $line;
  } else {
    print $middle_fh2 $line;
  }
}
close $middle_fh2;
close $input_fh1;

#連続していたピリオドを元に戻す
open( my $input_fh2, "<", "./middle2.txt" );
open( my $output_fh, ">", "./output.txt" );
while( my $line = <$input_fh2> ) {
  $line =~ s/hogehogehoge/\. \. \. /g;
  print $output_fh $line;
}
close $output_fh;
close $input_fh2;

1;
