use strict;
use warnings;
use utf8;
use Encode;
use Config::Tiny;
use Data::Dumper;
use Time::Piece;
use Time::Seconds;
use Time::Local;

my $num_of_prisoner = $ARGV[0];
my $num_of_color = $ARGV[1];
my $pass_mode = $ARGV[2];
#on or off
my $simultaneous_mode = $ARGV[3];
#on or off

my $setting_dir_path = "./setting";
mkdir encode( "cp932", $setting_dir_path );

make_setting_ini_file();

sub make_setting_ini_file {
  my $setting_ini_path = "${setting_dir_path}/setting.ini";
  open( my $setting_fh, ">", encode( "cp932", $setting_ini_path ) );

  print $setting_fh "num_of_prisoner=${num_of_prisoner}\n\n";
  my $prisoner_list_file_path = make_list( $num_of_prisoner, "prisoner" );
  print $setting_fh "prisoner_list_file_path=${prisoner_list_file_path}\n\n";

  print $setting_fh "num_of_color=${num_of_color}\n\n";
  my $color_list_file_path = make_list( $num_of_color, "color" );
  print $setting_fh "color_list_file_path=${color_list_file_path}\n\n";

  my $gragh_file_path = make_visibility_gragh_file( $num_of_prisoner );
  print $setting_fh "gragh_file_path=${gragh_file_path}\n\n";

  print $setting_fh "pass_mode=${pass_mode}\n\n";

  print $setting_fh "simultaneous_mode=${simultaneous_mode}\n\n";
  if ( $simultaneous_mode eq "off" ) {
    my $guess_order_file_path = make_guess_order_file( $num_of_prisoner );
    print $setting_fh "guess_order_file_path=${guess_order_file_path}\n\n";
  }
  close $setting_fh;
}

sub make_list {
  my ( $num, $mode ) = @_;
  my $file_path;
  if ( $mode eq "prisoner" ) {
    $file_path = "${setting_dir_path}/prisoner_list.txt";
  } elsif ( $mode eq "color" ) {
    $file_path = "${setting_dir_path}/color_list.txt";
  }
  open( my $fh, ">", encode( "cp932", $file_path ) );
  for ( my $i = 0; $i < $num; $i++ ){
    if ( $mode eq "prisoner" ) {
      print $fh "a_${i}\n";
    } elsif ( $mode eq "color" ) {
      print $fh "c_${i}\n";
    }
  }
  close $fh;
  return $file_path;
}

sub make_visibility_gragh_file {
  my ( $num ) = @_;
  my $file_path = "${setting_dir_path}/visibility_gragh.txt";
  open( my $fh, ">", encode( "cp932", $file_path ) );
  for ( my $i = 0; $i < $num; $i++ ){
    print $fh "\[a_${i}\]\n";
    for ( my $j = 0; $j < $num; $j++ ){
      if ( $i != $j ) {
        print $fh "a_${j}\n";
      }
    }
    print $fh "\n";
  }
  close $fh;
  return $file_path;
}

sub make_guess_order_file {
  my ( $num ) = @_;
  my $file_path = "${setting_dir_path}/guess_order.txt";
  open( my $fh, ">", encode( "cp932", $file_path ) );
  for ( my $i = 0; $i < $num; $i++ ){
    print $fh "\[${i}\]\n";
    for ( my $j = 0; $j < $num; $j++ ){
      print $fh "a_${j}\n";
    }
    print $fh "\n";
  }
  close $fh;
  return $file_path;
}

1;
