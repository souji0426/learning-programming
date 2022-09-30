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

my $time_stamp = make_time_stamp();
my $calc_data_dir_path = "./calc_data_${time_stamp}";
mkdir encode_cp932( $calc_data_dir_path );

my $result_data_dir_path = "./result_data";
mkdir encode_cp932( $result_data_dir_path );

sub make_time_stamp {
  my $today = localtime;
  my $year = $today->year;
  my $month = sprintf( "%02d", $today->mon );
  my $day = sprintf( "%02d", $today->mday );
  my $hour = sprintf( "%02d", $today->hour );
  my $min = sprintf( "%02d", $today->minute );
  my $sec = sprintf( "%02d", $today->sec );
  return join( "-", ( $year, $month, $day, $hour, $min, $sec ) );
}

my $log_messeage = [];
my $data = {};
$data->{"sum_of_process_time"} = 0;

calc();

sub calc {
  my $coloring_list_file_path = make_coloring_list();
  my $strategy_list_file_path = make_strategy_list( $coloring_list_file_path );
  make_indistinguishable_coloring_list( $coloring_list_file_path );
  make_chooseable_strategy_list( $strategy_list_file_path );
  calc_num_of_predictor( $data );
  my $predictor_list_file_path = make_predictor_list();
  analysis_predictor( $coloring_list_file_path, $strategy_list_file_path, $predictor_list_file_path );
  make_data_of_answer_data( $predictor_list_file_path );
  if ( $setting->{"pass_mode"} eq "off" and $setting->{"simultaneous_mode"} eq "on" ) {
   output_minimal_predictor_result( $coloring_list_file_path, $strategy_list_file_path, $predictor_list_file_path );
  }
  #print Dumper $data;
}

#------------------------------------------------------------------

sub make_coloring_list {
  my $process_name = "全coloringリスト作成";
  my $start_time = subroutine_start( $process_name );

  my $coloring_list_file_name = "coloring_list.txt";
  my $coloring_list_file_path = "${calc_data_dir_path}/${coloring_list_file_name}";
  my $num_of_prisoner = $setting->{"num_of_prisoner"};
  my $color_list_file_path = $setting->{"color_list_file_path"};

  my $calc_file_path;
  my $prisoner_list = read_list( "prisoner" );
  my $color_list = read_list( "color" );

  my $first = 1;
  my $last = 0;
  my $calc_counter = 0;
  foreach my $prisoner_name ( @$prisoner_list ) {

    if ( $first ) {

      $calc_file_path = "${calc_data_dir_path}/calc_${calc_counter}.txt";
      open( my $calc_fh, ">", encode_cp932( $calc_file_path ) );
      foreach my $color_name ( @$color_list ) {
        print $calc_fh "${prisoner_name}-${color_name}\n";
      }
      close $calc_fh;
      $calc_counter++;
      $first = 0;

    } else {
      my $last_counter = $calc_counter-1;
      my $last_calc_file_path = "${calc_data_dir_path}/calc_${last_counter}.txt";
      my $now_calc_file_path = "${calc_data_dir_path}/calc_${calc_counter}.txt";
      open( my $last_calc_fh, "<", encode_cp932( $last_calc_file_path ) );
      open( my $now_calc_fh, ">", encode_cp932( $now_calc_file_path ) );
      while ( my $last_line = <$last_calc_fh> ) {
        chomp $last_line;
        foreach my $color_name ( @$color_list ) {
          print $now_calc_fh "$last_line,${prisoner_name}-${color_name}\n";
        }
      }
      close $last_calc_fh;
      unlink encode_cp932( $last_calc_file_path );
      close $now_calc_fh;
      $calc_counter++;

      if ( $num_of_prisoner == $calc_counter ) {
        open( my $coloring_fh, ">", $coloring_list_file_path );
        open( my $now_calc_fh, "<", encode_cp932( $now_calc_file_path ) );
        my $coloring_counter = 0;
        while ( my $now_line = <$now_calc_fh> ) {
          print $coloring_fh "${coloring_counter}:" . $now_line;
          $coloring_counter++;
        }
        close $now_calc_fh;
        close $coloring_fh;
        unlink encode_cp932( $now_calc_file_path );
        $data->{"num_of_coloring"} = $coloring_counter;
      }
    }
  }
  subroutine_end( $start_time, $process_name );
  copy( encode_cp932( $coloring_list_file_path ), encode_cp932( "${result_data_dir_path}/${coloring_list_file_name}" ) );
  return $coloring_list_file_path;
}

#------------------------------------------------------------------
sub make_strategy_list {
  my ( $coloring_list_file_path ) = @_;

  my $process_name = "全strategyリスト作成";
  my $start_time = subroutine_start( $process_name );

  my $num_of_coloring = get_num_of_line( $coloring_list_file_path );
  my $strategy_list_file_name = "strategy_list.txt";
  my $strategy_list_file_path = "${calc_data_dir_path}/strategy_list.txt";
  my $color_list = read_list( "color" );
  if ( $setting->{"pass_mode"} eq "on" ) {
    my @array = @$color_list;
    push ( @array, "p" );
    $color_list = \@array;
  }
  my $num_of_color = @$color_list;
  open( my $coloring_list_fh, "<", encode_cp932( $coloring_list_file_path ) );

  my $first = 1;
  my $calc_counter = 0;
  my $calc_file_path;

  while( my $line = <$coloring_list_fh> ) {
    my $line_counter = 1;
    chomp $line;
    my ( $coloring_name, $coloring_data ) = read_function_data( $line );

    if ( $first ) {
      $calc_file_path = "${calc_data_dir_path}/calc_${calc_counter}.txt";

      my $num_of_target_file = $num_of_coloring * $num_of_color;

      open( my $calc_fh, ">", encode_cp932( $calc_file_path ) );
      foreach my $color_name ( @$color_list ) {
        print $calc_fh "${coloring_name}-${color_name}\n";
        print_process_for_making_function_list(
        $process_name, $start_time, $calc_counter+1, $num_of_coloring, $line_counter, $num_of_target_file );
        $line_counter++;
      }
      close $calc_fh;
      $calc_counter++;
      $first = 0;

    } else {

      my $last_counter = $calc_counter-1;
      my $last_calc_file_path = "${calc_data_dir_path}/calc_${last_counter}.txt";
      my $now_calc_file_path = "${calc_data_dir_path}/calc_${calc_counter}.txt";

      my $num_of_target_file = get_num_of_line( $last_calc_file_path ) * $num_of_color;

      open( my $last_calc_fh, "<", encode_cp932( $last_calc_file_path ) );
      open( my $now_calc_fh, ">", encode_cp932( $now_calc_file_path ) );
      while ( my $last_line = <$last_calc_fh> ) {
        chomp $last_line;
        foreach my $color_name ( @$color_list ) {
          print $now_calc_fh "$last_line,${coloring_name}-${color_name}\n";
          print_process_for_making_function_list(
          $process_name, $start_time, $calc_counter+1, $num_of_coloring, $line_counter, $num_of_target_file );
          $line_counter++;
        }
      }
      close $last_calc_fh;
      unlink encode_cp932( $last_calc_file_path );
      close $now_calc_fh;
      $calc_counter++;

      if ( $num_of_coloring == $calc_counter ) {
        open( my $strategy_list_fh, ">", $strategy_list_file_path );
        open( my $now_calc_fh, "<", encode_cp932( $now_calc_file_path ) );
        my $strategy_counter = 0;
        while ( my $now_line = <$now_calc_fh> ) {
          print $strategy_list_fh "${strategy_counter}:" . $now_line;
          $strategy_counter++;
        }
        close $now_calc_fh;
        close $strategy_list_fh;
        unlink encode_cp932( $now_calc_file_path );
        $data->{"num_of_strategy"} = $strategy_counter;
      }

    }
  }
  close $coloring_list_fh;

  subroutine_end( $start_time, $process_name );
  copy( encode_cp932( $strategy_list_file_path ), encode_cp932( "${result_data_dir_path}/${strategy_list_file_name}" ) );
  return $strategy_list_file_path;
}
#------------------------------------------------------------------

sub make_indistinguishable_coloring_list {
  my ( $coloring_list_file_path ) = @_;

  my $process_name = "各囚人のindistinguishable_coloringリスト作成";
  my $start_time = subroutine_start( $process_name );

  my $prisoner_list = read_list( "prisoner" );

  foreach my $prisoner_name ( @$prisoner_list ) {
    my $gragh_file_path = $setting->{"gragh_file_path"};
    my ( $can_see_list, $can_not_see_list ) = read_gragh_for_one_prisoner( $prisoner_name );

    my $calc_counter = 0;
    my $calc_file_path = "${calc_data_dir_path}/calc_${calc_counter}.txt";
    copy( $coloring_list_file_path, $calc_file_path );
    my $num_of_coloring = get_num_of_line( $calc_file_path );

    my $indistinguishable_coloring_list_txt_path = "${calc_data_dir_path}/indistinguishable_coloring_list_of_${prisoner_name}.txt";
    open( my $indistinguishable_coloring_fh, ">", encode_cp932( $indistinguishable_coloring_list_txt_path ) );

    for ( my $i = 0; $i < $num_of_coloring; $i++ ){
      my $now_counter = $calc_counter+1;
      my $last_calc_file_path = "${calc_data_dir_path}/calc_${calc_counter}.txt";;
      my $now_calc_file_path = "${calc_data_dir_path}/calc_${now_counter}.txt";
      open( my $last_calc_fh, "<", encode_cp932( $last_calc_file_path ) );
      open( my $now_calc_fh, ">", encode_cp932( $now_calc_file_path ) );
      my $start = 1;
      my ( $target_coloring_name, $target_coloring_data );
      my @indistinguishable_coloring_list_of_target;
      while ( my $last_line = <$last_calc_fh> ) {
        chomp $last_line;
        if ( $start ) {
          ( $target_coloring_name, $target_coloring_data ) = read_function_data( $last_line );
          push( @indistinguishable_coloring_list_of_target, $target_coloring_name );
          $start = 0;
        } else {

          my ( $next_target_coloring_name, $next_target_coloring_data ) = read_function_data( $last_line );
          if ( is_indistinguish( $can_see_list, $target_coloring_data, $next_target_coloring_data ) ) {
            push( @indistinguishable_coloring_list_of_target, $next_target_coloring_name );
          } else {
            print $now_calc_fh $last_line . "\n";
          }

        }
      }
      close $last_calc_fh;
      unlink encode_cp932( $last_calc_file_path );
      close $now_calc_fh;

      print $indistinguishable_coloring_fh join( ",", @indistinguishable_coloring_list_of_target ) . "\n";

      if ( get_num_of_line( $now_calc_file_path ) == 0 ) {
        unlink encode_cp932( $now_calc_file_path );
        last;
      }

      $calc_counter++;
    }

    close $indistinguishable_coloring_fh;
  }
  subroutine_end( $start_time, $process_name );
}

sub read_gragh_for_one_prisoner {
  my ( $prisoner_name ) = @_;
  my $prisoner_list = read_list( "prisoner" );
  my $can_see_list = [];
  my $gragh_file_path = $setting->{"gragh_file_path"};
  open( my $gragh_fh, "<", encode_cp932( $gragh_file_path) );
  my $is_target = 0;
  while( my $line = <$gragh_fh> ) {
    chomp $line;
    if ( $line eq "\[a_${prisoner_name}\]" ) {
      $is_target = 1;
    } elsif ( $line eq "" ) {
      $is_target = 0;
    } else {
      if ( $is_target ) {
        $line =~ s/a_//g;
        push( @$can_see_list, $line );
      }
    }
  }
  close $gragh_fh;

  my $can_not_see_list = [];
  foreach my $prisoner_name ( @$prisoner_list ) {
    if ( !grep { $_ eq $prisoner_name } @$can_see_list ) {
      push( @$can_not_see_list, $prisoner_name );
    }
  }

  return ( $can_see_list, $can_not_see_list );
}

sub get_num_of_line {
  my ( $file_path ) = @_;
  open( my $fh, "<", encode_cp932( $file_path ) );
  my $line_counter = 0;
  while( my $line = <$fh> ) {
    $line_counter++;
  }
  return $line_counter;
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

sub is_indistinguish {
  my ( $can_see_list, $data_one, $data_two ) = @_;
  my $is_indistinguish = 1;
  foreach my $prisoner_name ( @$can_see_list ) {
    #見えている範囲で違う色が見えた
    if ( $data_one->{$prisoner_name} ne $data_two->{$prisoner_name} ) {
      $is_indistinguish = 0;
      last;
    }
  }
  return $is_indistinguish;
}

#------------------------------------------------------------------

sub make_chooseable_strategy_list {
  my ( $strategy_list_file_path ) = @_;

  my $process_name = "各囚人のchooseable_strategyリスト作成";
  my $start_time = subroutine_start( $process_name );

  my $prisoner_list = read_list( "prisoner" );
  foreach my $prisoner_name ( @$prisoner_list ) {
    my $num_of_chooseable_strategy = 0;
    my $chooseable_strategy_list_txt_path = "${calc_data_dir_path}/chooseable_strategy_list_of_${prisoner_name}.txt";
    open( my $chooseable_strategy_list_fh, ">", encode_cp932( $chooseable_strategy_list_txt_path ) );

    my $indistinguishable_coloring_list_txt_path = "${calc_data_dir_path}/indistinguishable_coloring_list_of_${prisoner_name}.txt";
    my $indistinguishable_coloring_data = read_indistinguishable_coloring_list( $indistinguishable_coloring_list_txt_path );
    open( my $strategy_list_fh, "<", encode_cp932( $strategy_list_file_path ) );
    while( my $line = <$strategy_list_fh> ) {
      chomp $line;
      my ( $strategy_name, $strategy_data ) = read_function_data( $line );
      if ( is_chooseable( $indistinguishable_coloring_data, $strategy_data ) ) {
        print $chooseable_strategy_list_fh $strategy_name . "\n";
        $num_of_chooseable_strategy++;
      }
    }
    close $strategy_list_fh;
    close $chooseable_strategy_list_fh;
    $data->{"num_of_chooseable_strategy"}->{$prisoner_name} = $num_of_chooseable_strategy;
  }
  subroutine_end( $start_time, $process_name );
}

sub read_indistinguishable_coloring_list {
  my ( $file_path ) = @_;
  my %data;
  open( my $fh, "<", encode_cp932( $file_path) );
  my $class_counter = 0;
  while( my $line = <$fh> ) {
    chomp $line;
    my @class = split( ",", $line );
    $data{$class_counter} = \@class;
    $class_counter++;
  }
  close $fh;
  return \%data;
}

sub is_chooseable {
  my ( $indistinguishable_coloring_data, $strategy_data ) = @_;
  my $is_chooseable = 1;
  foreach my $class_counter ( keys %$indistinguishable_coloring_data ) {
    my @target_coloring = @{$indistinguishable_coloring_data->{$class_counter}};
    my $representative_coloring = $target_coloring[0];
    shift @target_coloring;
    my $color_at_representative_coloring = $strategy_data->{$representative_coloring};
    foreach my $coloring ( @target_coloring ) {
      if ( $strategy_data->{$coloring} ne $color_at_representative_coloring ) {
        $is_chooseable = 0;
        last;
      }
    }
  }
  return $is_chooseable;
}

sub calc_num_of_predictor {
  my ( $data ) = @_;
  my $result = 1;
  foreach my $prisoner_name ( keys %{$data->{"num_of_chooseable_strategy"}} ) {
    $result = $result * $data->{"num_of_chooseable_strategy"}->{$prisoner_name};
  }
  $data->{"num_of_predictor"} = $result;
}

#------------------------------------------------------------------

sub make_predictor_list {
  my $process_name = "全predictorリスト作成";
  my $start_time = subroutine_start( $process_name );

  my $predictor_list_file_name = "predictor_list.txt";
  my $predictor_list_file_path = "${calc_data_dir_path}/${predictor_list_file_name}";
  my $num_of_prisoner = $setting->{"num_of_prisoner"};
  my $prisoner_list = read_list( "prisoner" );
  my $first = 1;
  my $calc_counter = 0;
  my $calc_file_path;
  foreach my $prisoner_name ( @$prisoner_list ) {
    my $chooseable_strategy_list_txt_path = "${calc_data_dir_path}/chooseable_strategy_list_of_${prisoner_name}.txt";
    if ( $first ) {

      $calc_file_path = "${calc_data_dir_path}/calc_${calc_counter}.txt";
      open( my $calc_fh, ">", encode_cp932( $calc_file_path ) );

      my $num_of_target_file = get_num_of_line( $chooseable_strategy_list_txt_path );
      open( my $chooseable_strategy_list_fh, "<", encode_cp932( $chooseable_strategy_list_txt_path ) );
      my $line_counter = 1;
      while ( my $line = <$chooseable_strategy_list_fh> ) {
        chomp $line;
        print $calc_fh "${prisoner_name}-${line}\n";
        print_process_for_making_function_list(
        $process_name, $start_time, $calc_counter+1, $num_of_prisoner, $line_counter, $num_of_target_file );
        $line_counter++;
      }
      close $chooseable_strategy_list_fh;

      close $calc_fh;
      $calc_counter++;
      $first = 0;

    } else {

      my $last_counter = $calc_counter-1;
      my $last_calc_file_path = "${calc_data_dir_path}/calc_${last_counter}.txt";
      my $now_calc_file_path = "${calc_data_dir_path}/calc_${calc_counter}.txt";
      open( my $last_calc_fh, "<", encode_cp932( $last_calc_file_path ) );
      open( my $now_calc_fh, ">", encode_cp932( $now_calc_file_path ) );
      my $line_counter = 1;
      while ( my $last_line = <$last_calc_fh> ) {
        chomp $last_line;
        my $num_of_target_file = get_num_of_line( $last_calc_file_path ) * get_num_of_line( $chooseable_strategy_list_txt_path );
        open( my $chooseable_strategy_list_fh, "<", encode_cp932( $chooseable_strategy_list_txt_path ) );
        while ( my $line = <$chooseable_strategy_list_fh> ) {
          chomp $line;
          print $now_calc_fh "$last_line,${prisoner_name}-${line}\n";
          print_process_for_making_function_list(
          $process_name, $start_time, $calc_counter+1, $num_of_prisoner, $line_counter, $num_of_target_file );
          $line_counter++;
        }
        close $chooseable_strategy_list_fh;
      }
      close $last_calc_fh;
      unlink encode_cp932( $last_calc_file_path );
      close $now_calc_fh;
      $calc_counter++;

      if ( $num_of_prisoner == $calc_counter ) {
        open( my $predictor_list_fh, ">", encode_cp932( $predictor_list_file_path ) );
        open( my $now_calc_fh, "<", encode_cp932( $now_calc_file_path ) );
        my $predictor_counter = 0;
        while ( my $now_line = <$now_calc_fh> ) {
          print $predictor_list_fh "${predictor_counter}:" . $now_line;
          $predictor_counter++;
        }
        close $now_calc_fh;
        close $predictor_list_fh;
        unlink encode_cp932( $now_calc_file_path );
      }

    }
  }
  subroutine_end( $start_time, $process_name );
  copy( encode_cp932( $predictor_list_file_path ), encode_cp932( "${result_data_dir_path}/${predictor_list_file_name}" ) );
  return $predictor_list_file_path;
}

#------------------------------------------------------------------

sub analysis_predictor {
  my ( $coloring_list_file_path, $strategy_list_file_path, $predictor_list_file_path ) = @_;

  my $process_name = "全predictorシミュレーション";
  my $start_time = subroutine_start( $process_name );

  my $num_of_prisoner = $setting->{"num_of_prisoner"};
  my $prisoner_list = read_list( "prisoner" );

  open( my $predictor_list_fh, "<", encode_cp932( $predictor_list_file_path ) );

  my $predictor_counter = 0;
  my $num_of_predictor = $data->{"num_of_predictor"};
  while ( my $line = <$predictor_list_fh> ) {
    chomp $line;
    my ( $predictor_name, $predictor_data ) = read_function_data( $line );
    my $answer_result_file_name = "answer_result_${predictor_name}.txt";
    my $answer_result_file_path = "${calc_data_dir_path}/${answer_result_file_name}";
    open( my $answer_result_fh, ">", encode_cp932( $answer_result_file_path ) );
    open( my $coloring_list_fh, "<", encode_cp932( $coloring_list_file_path ) );
    while ( my $coloring_list_line = <$coloring_list_fh> ) {
      my %result_hash;
      chomp $coloring_list_line;
      my ( $coloring_name, $coloring_data ) = read_function_data( $coloring_list_line );
      foreach my $prisoner_name ( @$prisoner_list ) {
        my $strategy_name_of_prisoner = $predictor_data->{$prisoner_name};
        my $strategy_data = get_strategy_data( $strategy_list_file_path, $strategy_name_of_prisoner );
        my $result;
        if ( $strategy_data->{$coloring_name} eq "p" ) {
          $result = "p";
        } else {
          if ( $strategy_data->{$coloring_name} eq $coloring_data->{$prisoner_name} ) {
            $result = "1";
          } else {
            $result = "0";
          }
        }
        $result_hash{$prisoner_name} = $result;
      }

      my @result_array;
      foreach my $prisoner_name ( @$prisoner_list ) {
        my $result = $result_hash{$prisoner_name};
        push( @result_array, "${prisoner_name}-${result}" );
      }
      print $answer_result_fh "$coloring_name:" . join( ",", @result_array ) . "\n";
    }
    close $coloring_list_fh;
    close $answer_result_fh;
    copy( encode_cp932( $answer_result_file_path ),
          encode_cp932( "${result_data_dir_path}/${answer_result_file_name}" ) );
    print_process_for_predictor( $process_name, $start_time, $predictor_counter, $num_of_predictor );
    $predictor_counter++;
  }

  close $predictor_list_fh;
  subroutine_end( $start_time, $process_name );
}

sub get_strategy_data {
  my ( $strategy_list_file_path, $target_strategy_name ) = @_;
  my $data;
  open( my $strategy_list_fh, "<", encode_cp932( $strategy_list_file_path ) );
  while( my $line = <$strategy_list_fh> ) {
    chomp $line;
    my ( $strategy_name, $strategy_data ) = read_function_data( $line );
    if ( $target_strategy_name eq $strategy_name ) {
      $data = $strategy_data;
      last;
    }
  }
  close $strategy_list_fh;
  return $data;
}

#------------------------------------------------------------------

sub make_data_of_answer_data {
  my ( $predictor_list_file_path ) = @_;

  my $process_name = "全predictorシミュレーション結果解析";
  my $start_time = subroutine_start( $process_name );

  my $predictor_counter = 0;
  my $num_of_predictor = $data->{"num_of_predictor"};
  open( my $predictor_list_fh, "<", encode_cp932( $predictor_list_file_path ) );
  while ( my $line = <$predictor_list_fh> ) {
    chomp $line;
    my ( $predictor_name, $predictor_data ) = read_function_data( $line );
    my $answer_data_file_name = "answer_data_${predictor_name}.txt";
    my $answer_data_file_path = "${calc_data_dir_path}/${answer_data_file_name}";
    open( my $answer_data_fh, ">", encode_cp932( $answer_data_file_path ) );

    my $answer_result_file_path = "${calc_data_dir_path}/answer_result_${predictor_name}.txt";
    open( my $answer_result_fh, "<", encode_cp932( $answer_result_file_path ) );
    while ( my $line = <$answer_result_fh> ) {
      chomp $line;
      my ( $coloring_name, $answer_data ) = read_function_data( $line );

      my ( $num_of_correct_answer, $num_of_incorrect_answer, $num_of_pass_answer ) = ( 0, 0, 0 );
      my ( @correct_answer_list, @incorrect_answer_list, @pass_answer_list );
      foreach my $prisoner_name ( keys %$answer_data ) {
        if ( $answer_data->{$prisoner_name} eq "1" ) {
          $num_of_correct_answer++;
          push( @correct_answer_list, $prisoner_name );
        } elsif ( $answer_data->{$prisoner_name} eq "0" ) {
          $num_of_incorrect_answer++;
          push( @incorrect_answer_list, $prisoner_name );
        } elsif ( $setting->{"pass_mode"} eq "on" and $answer_data->{$prisoner_name} eq "p" ) {
          $num_of_pass_answer++;
          push( @pass_answer_list, $prisoner_name );
        }
      }
      print $answer_data_fh "${coloring_name}:";
      print $answer_data_fh "num_of_correct_answer-${num_of_correct_answer},";
      print $answer_data_fh "correct_answer-" . join( "-", @correct_answer_list ) . ",";
      print $answer_data_fh "num_of_incorrect_answer-${num_of_incorrect_answer},";
      print $answer_data_fh "incorrect_answer-" . join( "-", @incorrect_answer_list );
      if ( $setting->{"pass_mode"} eq "off" ) {
        print $answer_data_fh "\n";
      } else {
        print $answer_data_fh ",";
        print $answer_data_fh "num_of_pass_answer-${num_of_pass_answer},";
        print $answer_data_fh "pass_answer-" . join( "-", @pass_answer_list ) . "\n";
      }

    }
    close $answer_result_fh;
    close $answer_data_fh;
    copy( encode_cp932( $answer_data_file_path ),
          encode_cp932( "${result_data_dir_path}/${answer_data_file_name}" ) );
    print_process_for_predictor( $process_name, $start_time, $predictor_counter, $num_of_predictor );
    $predictor_counter++;
  }
  close $predictor_list_fh;
  subroutine_end( $start_time, $process_name );
}

#------------------------------------------------------------------

sub output_minimal_predictor_result {
  my ( $coloring_list_file_path, $strategy_list_file_path, $predictor_list_file_path ) = @_;

  my $process_name = "全predictorのminimalチェック";
  my $start_time = subroutine_start( $process_name );

  my $minimal_predictor_result_file_name = "minimal_predictor_result.txt";
  my $minimal_predictor_result_file_path = "${calc_data_dir_path}/${minimal_predictor_result_file_name}.txt";
  open( my $minimal_predictor_result_fh, ">", encode_cp932( $minimal_predictor_result_file_path ) );
  open( my $predictor_list_fh, "<", encode_cp932( $predictor_list_file_path ) );

  my $predictor_counter = 0;
  my $num_of_predictor = $data->{"num_of_predictor"};
  while ( my $line = <$predictor_list_fh> ) {
    chomp $line;
    my ( $predictor_name, $predictor_data ) = read_function_data( $line );
    my $is_minimal_predictor = 1;
    my $answer_data_file_path = "${calc_data_dir_path}/answer_data_${predictor_name}.txt";
    open( my $answer_data_fh, "<", encode_cp932( $answer_data_file_path ) );
    while ( my $answer_data_line = <$answer_data_fh> ) {
      chomp $answer_data_line;
      my ( $coloring_name, $answer_data ) = read_function_data( $answer_data_line );
      if ( $answer_data->{"num_of_correct_answer"} == "0" ) {
        $is_minimal_predictor = 0;
        last;
      }
    }
    if ( $is_minimal_predictor ) {
      print $minimal_predictor_result_fh "${predictor_name}\n";
    }
    close $answer_data_fh;
    print_process_for_predictor( $process_name, $start_time, $predictor_counter, $num_of_predictor );
    $predictor_counter++;
  }

  close $minimal_predictor_result_fh;
  subroutine_end( $start_time, $process_name );
  copy( encode_cp932( $minimal_predictor_result_file_path ),
        encode_cp932( "${result_data_dir_path}/${minimal_predictor_result_file_name}" ) );
}

#------------------------------------------------------------------

sub read_list {
  my ( $mode ) = @_;
  my $list = [];

  open( my $list_fh, "<", encode_cp932( $setting->{"${mode}_list_file_path"} ) );
  while( my $line = <$list_fh> ) {
    chomp $line;
    if ( $mode eq "prisoner" ) {
      $line =~ s/a_//g;
    } elsif ( $mode eq "color" ) {
      $line =~ s/c_//g;
    }
    push( @$list, $line );
  }
  close $list_fh;
  return $list;
}

sub encode_cp932 {
  my ( $str ) = @_;
  return encode( "cp932", $str );
}

sub make_process_time_log {
  my ( $second ) = @_;
  if ( $second < 60 ) {
    return "経過時間：${second}秒";
  } elsif ( $second > 59 ) {
    my $minutes = int( $second / 60 );
    $second = $second % 60;
    return "経過時間：${minutes}分${second}秒";
  }
}

sub subroutine_start {
  my ( $str ) = @_;
  system( "cls\n" );
  push( @$log_messeage, "${str}開始！" );
  print encode_cp932( join( "\n\n", @$log_messeage ) );
  return time;
}

sub print_process_for_making_function_list {
  my ( $str, $start_time, $calc_counter, $num_of_calc, $counter, $num_of_all ) = @_;
  my $degree_of_completion = int( ($counter/$num_of_all)*100 );
  my $now = time;
  my $process_time = $now - $start_time;
  pop @$log_messeage;
  push( @$log_messeage, "${str}中　　" .
  "（${calc_counter}／${num_of_calc}段階目）${degree_of_completion}％完了（${counter}／${num_of_all}）　　${process_time}秒経過" );
  system( "cls\n" );
  print encode_cp932( join( "\n\n", @$log_messeage ) );
}

sub print_process_for_predictor {
  my ( $str, $start_time, $counter, $num_of_all ) = @_;
  my $degree_of_completion = int( ($counter/$num_of_all)*100 );
  my $now = time;
  my $process_time = $now - $start_time;
  pop @$log_messeage;
  push( @$log_messeage, "${str}中　　" . "${degree_of_completion}％完了（${counter}／${num_of_all}）　　${process_time}秒経過" );
  system( "cls\n" );
  print encode_cp932( join( "\n\n", @$log_messeage ) );
}

sub subroutine_end {
  my ( $start_time, $str ) = @_;
  my $end_time = time;
  my $process_time = $end_time - $start_time;
  $data->{"sum_of_process_time"} += $process_time;
  my $process_time_log_messeage = make_process_time_log( $process_time );
  pop @$log_messeage;
  push( @$log_messeage, "${str}完了！　　" . $process_time_log_messeage );
  system( "cls\n" );
  print encode_cp932( join( "\n\n", @$log_messeage ) );
}

1;
