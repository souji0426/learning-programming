use strict;
use warnings;
use utf8;
use Encode;
use File::Copy;

my $input_file_path = "./input.txt";

my $counter = 0;
#ピリオドをすべてピリオド＋改行に変換
#ただしピリオドが連続する場合は一旦別の文字列に変換しておく
$input_file_path = add_new_line_in_period( $input_file_path, $counter );
$counter++;

#行末がピリオドでない行をくっつける
$input_file_path = del_invald_new_line( $input_file_path, $counter );
$counter++;

#文末以外で使用されているピリオドを元に戻す。
$input_file_path = del_invald_period_In_new_line( $input_file_path, $counter );
$counter++;

#ピリオド＋文献番号で改行する
$input_file_path = convert_period_and_reference( $input_file_path, $counter );
$counter++;

#連続していたピリオドを元に戻す
$input_file_path = convert_hoge( $input_file_path, $counter );
$counter++;

my $output_file_path = "./output.txt";
copy( $input_file_path, $output_file_path );

sub add_new_line_in_period {
  my ( $path, $counter ) = @_;
  my $middle_file_path = "./middle${counter}.txt";

  open( my $input_fh, "<", $path );
  open( my $middle_fh, ">", $middle_file_path );
  while( my $line = <$input_fh> ) {
    $line =~ s/\. \. \. /hogehogehoge/g;
    $line =~ s/\. /\.\n/g;
    print $middle_fh $line;
  }

  close $middle_fh;
  close $input_fh;

  return $middle_file_path;
}

sub del_invald_new_line {
  my ( $path, $counter ) = @_;
  my $middle_file_path = "./middle${counter}.txt";

  open( my $input_fh, "<", $path );
  open( my $middle_fh, ">", $middle_file_path );
  while( my $line = <$input_fh> ) {
    if ( $line !~ /\.\n/ ) {
      $line =~ s/\n//g;
    }
    print $middle_fh $line;
  }

  close $middle_fh;
  close $input_fh;

  return $middle_file_path;
}

sub del_invald_period_In_new_line {
  my ( $path, $counter ) = @_;
  my $middle_file_path = "./middle${counter}.txt";

  open( my $input_fh, "<", $path );
  open( my $middle_fh, ">", $middle_file_path );
  while( my $line = <$input_fh> ) {
    #いずれ設定ファイルとかでリスト化する
    if ( $line =~ /Dr\.\n/ or
          $line =~ /Mr\.\n/ or
          $line =~ /Ph\.\n/ or
          $line =~ /D\.\n/ or
          $line =~ /O\.K\.\n/ or
          $line =~ /i\.o\.\n/ ) {
      $line =~ s/\n/ /g;
    }
    print $middle_fh $line;
  }

  close $middle_fh;
  close $input_fh;

  return $middle_file_path;
}

sub convert_period_and_reference {
  my ( $path, $counter ) = @_;
  my $middle_file_path = "./middle${counter}.txt";

  open( my $input_fh, "<", $path );
  open( my $middle_fh, ">", $middle_file_path );
  while( my $line = <$input_fh> ) {
    $line =~ s/\]\[/hoge/g;
    $line =~ s/\] */\]\n/g;
    $line =~ s/hoge/\]\[/g;
    print $middle_fh $line;
  }
  close $middle_fh;
  close $input_fh;

  return $middle_file_path;
  }

sub convert_hoge {
  my ( $path, $counter ) = @_;
  my $middle_file_path = "./middle${counter}.txt";

  open( my $input_fh, "<", $path );
  open( my $middle_fh, ">", $middle_file_path );
  while( my $line = <$input_fh> ) {
    $line =~ s/hogehogehoge/\. \. \. /g;
    print $middle_fh $line;
  }

  close $middle_fh;
  close $input_fh;

  return $middle_file_path;
}

1;
