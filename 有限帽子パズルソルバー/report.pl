use strict;
use warnings;
use utf8;
use Encode;
use Config::Tiny;
use Data::Dumper;
use Time::Piece;
use Time::Seconds;
use Time::Local;
use File::Copy;

my $setting = Config::Tiny->read( encode_cp932( "./setting/setting.ini" ) );
$setting = $setting->{"_"};

my @prisoner_list;
open( my $prisoner_list_fh, "<", encode_cp932( $setting->{"prisoner_list_file_path"} ) );
while( my $line =<$prisoner_list_fh> ) {
  chomp $line;
  push( @prisoner_list, $line );
}
close $prisoner_list_fh;

my %code_to_color_name = ( "c_0"=>"白", "c_1"=>"黒", "c_2"=>"赤" );

open( my $color_list_fh, "<", encode_cp932( $setting->{"color_list_file_path"} ) );
my @color_list;
while( my $line =<$color_list_fh> ) {
  chomp $line;
  push( @color_list, $code_to_color_name{$line} );
}
close $color_list_fh;

main();

sub main {
  my $report_file_path = "./result_data/report.txt";
  open( my $report_fh, ">", encode_cp932( $report_file_path ) );

  print $report_fh encode_cp932( "ー" x 5 . "パズルの解析結果" . "ー" x 5 . "\n\n" );
  output_setting( $report_fh );

  print $report_fh encode_cp932( "ー" x 5 . "各種戦略情報" . "ー" x 5 . "\n\n" );
  output_minimal_predictor_report( $report_fh );


  close $report_fh;
}

sub output_setting {
  my ( $fh ) = @_;

  print $fh encode_cp932( "ー" x 5 . "囚人数・色数の設定\n\n" );

  my $num_of_prisoner = $setting->{"num_of_prisoner"};
  print $fh encode_cp932( "囚人数：${num_of_prisoner}人\n\n" );

  my @prisoner_list;
  open( my $prisoner_list_fh, "<", encode_cp932( $setting->{"prisoner_list_file_path"} ) );
  while( my $line =<$prisoner_list_fh> ) {
    chomp $line;
    push( @prisoner_list, $line );
  }
  close $prisoner_list_fh;
  print $fh encode_cp932( "囚人リスト：" . join( "、", @prisoner_list ) . "\n\n" );

  my $num_of_color = $setting->{"num_of_color"};
  print $fh encode_cp932( "帽子につく色の数：${num_of_color}個\n\n" );

  print $fh encode_cp932( "色のリスト：" . join( "、", @color_list ) . "\n\n" );

  print $fh encode_cp932( "ー" x 5 . "帽子の見え方の設定\n\n" );
  my $gragh_file_path = $setting->{"gragh_file_path"};
  foreach my $prisoner_name ( @prisoner_list ) {
    my ( $can_see_list, $can_not_see_list ) = read_gragh_for_one_prisoner( \@prisoner_list, $prisoner_name );
    print $fh encode_cp932( "囚人${prisoner_name}について\n" );
    my $num_of_can_see_list = @$can_see_list;
    if ( $num_of_can_see_list == 0 ) {
      print $fh encode_cp932( "見えている囚人：無し" );
    } elsif ( $num_of_can_see_list > 0 ) {
      print $fh encode_cp932( "見えている囚人：". join( "、", @$can_see_list ) );
    }
    print $fh "\n";
    my $num_of_can_not_see_list = @$can_not_see_list;
    if ( $num_of_can_not_see_list == 0 ) {
      print $fh encode_cp932( "見えていない囚人：無し" );
    } elsif ( $num_of_can_not_see_list > 0 ) {
      print $fh encode_cp932( "見えていない囚人：". join( "、", @$can_not_see_list ) );
    }
    print $fh "\n\n";
  }

  my $pass_mode = $setting->{"pass_mode"};
  my $simultaneous_mode = $setting->{"simultaneous_mode"};

  print $fh "\n";
}

sub read_gragh_for_one_prisoner {
  my ( $prisoner_list, $prisoner_name ) = @_;
  my @can_see_list;
  my $gragh_file_path = $setting->{"gragh_file_path"};
  open( my $gragh_fh, "<", encode_cp932( $gragh_file_path) );
  my $is_target = 0;
  while( my $line = <$gragh_fh> ) {
    chomp $line;
    if ( $line eq "\[${prisoner_name}\]" ) {
      $is_target = 1;
    } elsif ( $line eq "" ) {
      $is_target = 0;
    } else {
      if ( $is_target ) {
        push( @can_see_list, $line );
      }
    }
  }
  close $gragh_fh;

  my @can_not_see_list;
  foreach my $name ( @$prisoner_list ) {
    if ( !grep { $_ eq $name } @can_see_list ) {
      if ( $name ne $prisoner_name ) {
        push( @can_not_see_list, $name );
      }
    }
  }
  return ( \@can_see_list, \@can_not_see_list );
}

sub output_minimal_predictor_report {
  my ( $fh ) = @_;

  print $fh encode_cp932( "ー" x 5 . "最低でも1人は正解する戦略について\n\n" );

  my $minimal_predictor_result_file_path = "./result_data/minimal_predictor_result.txt";
  my $minimal_predictor_code_list = [];
  open( my $minimal_predictor_result_fh, "<", encode_cp932( $minimal_predictor_result_file_path ) );
  while( my $line =<$minimal_predictor_result_fh> ) {
    chomp $line;
    push( @$minimal_predictor_code_list, $line );
  }
  close $minimal_predictor_result_fh;

  my $num_of_minimal_predictor = @$minimal_predictor_code_list;
  if( $num_of_minimal_predictor == 0 ) {
    print $fh encode_cp932( "存在チェック：無し\n" );
  } elsif ( $num_of_minimal_predictor > 0 ) {
    print $fh encode_cp932( "存在チェック：${num_of_minimal_predictor}種類存在。↓詳細↓\n\n" );

    my $minimal_predictor_counter = 1;
    foreach my $minimal_predictor_code ( @$minimal_predictor_code_list ) {
      print $fh encode_cp932( "${minimal_predictor_counter}つ目\n" );

      my $coloring_list_file_path = "./result_data/coloring_list.txt";
      open( my $color_list_fh, "<", $coloring_list_file_path );
      my $coloring_counter = 1;
      while( my $line = <$color_list_fh> ) {
        chomp $line;
        my ( $coloring_name, $coloring_data ) = read_function_data( $line );
        my @data;
        push( @data, "帽子の被せ方その${coloring_counter}：" );
        foreach my $prisoner_code ( keys %$coloring_data ) {
          my $color_code = $coloring_data->{$prisoner_code};
          push( @data, "a_${prisoner_code}⇒" . $code_to_color_name{"c_${color_code}"} );
        }
        print $fh encode_cp932( join( "\t", @data ) . "\n" );

        @data = ();
        push( @data, "そのときの発言：" );
        my $answer_result_file_path = "./result_data/answer_result_${minimal_predictor_code}.txt";
        open( my $answer_result_fh, "<", encode_cp932( $answer_result_file_path ) );
        while( my $line = <$answer_result_fh> ) {
          if ( $line =~ /^${coloring_name}:/ ) {
            chomp $line;
            my ( $coloring_name, $answer ) = read_function_data( $line );
            foreach my $prisoner_code ( keys %$answer ) {
              my $color_code = $answer->{$prisoner_code};
              push( @data, "a_${prisoner_code}⇒" . $code_to_color_name{"c_${color_code}"} );
            }
          }
        }
        print $fh encode_cp932( join( "\t", @data ) . "\n" );
        close $answer_result_fh;

        @data = ();
        push( @data, "各人数：" );
        my $answer_data_file_path = "./result_data/answer_data_${minimal_predictor_code}.txt";
        open( my $answer_data_fh, "<", encode_cp932( $answer_data_file_path ) );
        while( my $line = <$answer_data_fh> ) {
          if ( $line =~ /^${coloring_name}:/ ) {
            chomp $line;
            my ( $coloring_name, $answer_data ) = read_function_data( $line );
            my $num_of_correct_answer = $answer_data->{"num_of_correct_answer"};
            push( @data, "正解者数⇒${num_of_correct_answer}人" );
            my $num_of_incorrect_answer = $answer_data->{"num_of_incorrect_answer"};
            push( @data, "不正解者数⇒${num_of_incorrect_answer}人" );
          }
        }
        print $fh encode_cp932( join( "\t", @data ) . "\n" );
        close $answer_data_fh;
        print $fh encode_cp932( "\n\n" );
        $coloring_counter++;

      }
      close $color_list_fh;
      print $fh encode_cp932( "\n\n" );
      $minimal_predictor_counter++;
    }
  }
}

sub read_function_data {
  my ( $line) = @_;
  my @data_in_one_line = split( ":", $line );
  my $function_name = $data_in_one_line[0];
  my %function_data;
  foreach my $rule ( split( ",", $data_in_one_line[1] ) ) {
    my @data = split( "-", $rule );
    $function_data{$data[0]} = $data[1];
  }
  return ( $function_name, \%function_data );
}

sub encode_cp932 {
  my ( $str ) = @_;
  return encode( "cp932", $str );
}


1;
