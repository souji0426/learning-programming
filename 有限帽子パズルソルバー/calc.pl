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

my $setting = Config::Tiny->read( encode( "cp932", "./setting/setting.ini" ) );
$setting = $setting->{"_"};

my $time_stamp = make_time_stamp();
my $calc_data_dir_path = "./calc_data_${time_stamp}";
mkdir encode( "cp932", $calc_data_dir_path );

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

calc();

sub calc {
  my $coloring_list_file_path = make_coloring_list();
  my $all_strategy_list_file_path = make_all_strategy_list( $coloring_list_file_path );
  make_indistinguishable_coloring_list( $coloring_list_file_path );
  make_chooseable_strategy_list( $all_strategy_list_file_path );
  my $predictor_list_file_path = make_predictor_list();
  my $analysis_data_file_path = analysis_predictor( $coloring_list_file_path, $all_strategy_list_file_path, $predictor_list_file_path );
}

#------------------------------------------------------------------

sub make_coloring_list {
  my $coloring_list_file_path = "${calc_data_dir_path}/coloring_list.txt";
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
      open( my $calc_fh, ">", encode( "cp932", $calc_file_path ) );
      foreach my $color_name ( @$color_list ) {
        print $calc_fh "${prisoner_name}->${color_name}\n";
      }
      close $calc_fh;
      $calc_counter++;
      $first = 0;

    } else {
      my $last_counter = $calc_counter-1;
      my $last_calc_file_path = "${calc_data_dir_path}/calc_${last_counter}.txt";
      my $now_calc_file_path = "${calc_data_dir_path}/calc_${calc_counter}.txt";
      open( my $last_calc_fh, "<", encode( "cp932", $last_calc_file_path ) );
      open( my $now_calc_fh, ">", encode( "cp932", $now_calc_file_path ) );
      while ( my $last_line = <$last_calc_fh> ) {
        chomp $last_line;
        foreach my $color_name ( @$color_list ) {
          print $now_calc_fh "$last_line,${prisoner_name}->${color_name}\n";
        }
      }
      close $last_calc_fh;
      unlink $last_calc_file_path;
      close $now_calc_fh;
      $calc_counter++;

      if ( $num_of_prisoner == $calc_counter ) {
        open( my $coloring_fh, ">", $coloring_list_file_path );
        open( my $now_calc_fh, "<", encode( "cp932", $now_calc_file_path ) );
        my $coloring_counter = 0;
        while ( my $now_line = <$now_calc_fh> ) {
          print $coloring_fh "f_${coloring_counter}:" . $now_line;
          $coloring_counter++;
        }
        close $now_calc_fh;
        close $coloring_fh;
        unlink $now_calc_file_path;
      }

    }
  }
  return $coloring_list_file_path;
}

#------------------------------------------------------------------
sub make_all_strategy_list {
  my ( $coloring_list_file_path ) = @_;
  my $num_of_coloring = get_num_of_line( $coloring_list_file_path );
  my $all_strategy_list_file_path = "${calc_data_dir_path}/all_strategy_list.txt";
  my $color_list = read_list( "color" );
  if ( $setting->{"pass_mode"} eq "on" ) {
    my @array = @$color_list;
    push ( @array, "pass" );
    $color_list = \@array;
  }
  open( my $coloring_list_fh, "<", $coloring_list_file_path );

  my $first = 1;
  my $calc_counter = 0;
  my $calc_file_path;
  while( my $line = <$coloring_list_fh> ) {
    chomp $line;
    my ( $coloring_name, $coloring_data ) = read_function_data( $line );
    if ( $first ) {

      $calc_file_path = "${calc_data_dir_path}/calc_${calc_counter}.txt";
      open( my $calc_fh, ">", encode( "cp932", $calc_file_path ) );
      foreach my $color_name ( @$color_list ) {
        print $calc_fh "${coloring_name}->${color_name}\n";
        #print "${coloring_name}->${color_name}\n";
      }
      close $calc_fh;
      $calc_counter++;
      $first = 0;

    } else {

      my $last_counter = $calc_counter-1;
      my $last_calc_file_path = "${calc_data_dir_path}/calc_${last_counter}.txt";
      my $now_calc_file_path = "${calc_data_dir_path}/calc_${calc_counter}.txt";
      open( my $last_calc_fh, "<", encode( "cp932", $last_calc_file_path ) );
      open( my $now_calc_fh, ">", encode( "cp932", $now_calc_file_path ) );
      while ( my $last_line = <$last_calc_fh> ) {
        chomp $last_line;
        foreach my $color_name ( @$color_list ) {
          print $now_calc_fh "$last_line,${coloring_name}->${color_name}\n";
          #print "$last_line,${coloring_name}->${color_name}\n";
        }
      }
      close $last_calc_fh;
      unlink $last_calc_file_path;
      close $now_calc_fh;
      $calc_counter++;

      if ( $num_of_coloring == $calc_counter ) {
        open( my $all_strategy_list_fh, ">", $all_strategy_list_file_path );
        open( my $now_calc_fh, "<", encode( "cp932", $now_calc_file_path ) );
        my $strategy_counter = 0;
        while ( my $now_line = <$now_calc_fh> ) {
          print $all_strategy_list_fh "G_${strategy_counter}:" . $now_line;
          $strategy_counter++;
        }
        close $now_calc_fh;
        close $all_strategy_list_fh;
        unlink $now_calc_file_path;
      }

    }
  }

  close $coloring_list_fh;

  return $all_strategy_list_file_path;
}
#------------------------------------------------------------------

sub make_indistinguishable_coloring_list {
  my ( $coloring_list_file_path ) = @_;
  my $prisoner_list = read_list( "prisoner" );

  foreach my $prisoner_name ( @$prisoner_list ) {
    my $gragh_file_path = $setting->{"gragh_file_path"};
    my ( $can_see_list, $not_see_list ) = read_gragh_for_one_prisoner( $prisoner_name );

    my $calc_counter = 0;
    my $calc_file_path = "${calc_data_dir_path}/calc_${calc_counter}.txt";
    copy( $coloring_list_file_path, $calc_file_path );
    my $num_of_coloring = get_num_of_line( $calc_file_path );

    my $indistinguishable_coloring_list_txt_path = "${calc_data_dir_path}/indistinguishable_coloring_list_of_${prisoner_name}.txt";
    open( my $indistinguishable_coloring_fh, ">", $indistinguishable_coloring_list_txt_path );

    for ( my $i = 0; $i < $num_of_coloring; $i++ ){
      my $now_counter = $calc_counter+1;
      my $last_calc_file_path = "${calc_data_dir_path}/calc_${calc_counter}.txt";;
      my $now_calc_file_path = "${calc_data_dir_path}/calc_${now_counter}.txt";
      open( my $last_calc_fh, "<", encode( "cp932", $last_calc_file_path ) );
      open( my $now_calc_fh, ">", encode( "cp932", $now_calc_file_path ) );
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
      unlink $last_calc_file_path;
      close $now_calc_fh;

      print $indistinguishable_coloring_fh join( ",", @indistinguishable_coloring_list_of_target ) . "\n";

      if ( get_num_of_line( $now_calc_file_path ) == 0 ) {
        unlink $now_calc_file_path;
        last;
      }

      $calc_counter++;
    }

    close $indistinguishable_coloring_fh;
  }
}

sub read_gragh_for_one_prisoner {
  my ( $prisoner_name ) = @_;
  my $prisoner_list = read_list( "prisoner" );
  my $can_see_list = [];
  my $gragh_file_path = $setting->{"gragh_file_path"};
  open( my $gragh_fh, "<", encode( "cp932", $gragh_file_path) );
  my $is_target = 0;
  while( my $line = <$gragh_fh> ) {
    chomp $line;
    if ( $line eq "\[${prisoner_name}\]" ) {
      $is_target = 1;
    } elsif ( $line eq "" ) {
      $is_target = 0;
    } else {
      if ( $is_target ) {
        push( @$can_see_list, $line );
      }
    }
  }
  close $gragh_fh;

  my $not_see_list = [];
  foreach my $prisoner_name ( @$prisoner_list ) {
    if ( !grep { $_ eq $prisoner_name } @$can_see_list ) {
      push( @$not_see_list, $prisoner_name );
    }
  }

  return ( $can_see_list, $not_see_list );
}

sub get_num_of_line {
  my ( $file_path ) = @_;
  open( my $fh, "<", encode( "cp932", $file_path ) );
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
    my @data = split( "->", $rule );
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
  my ( $all_strategy_list_file_path ) = @_;
  my $prisoner_list = read_list( "prisoner" );
  foreach my $prisoner_name ( @$prisoner_list ) {
    my $chooseable_strategy_list_txt_path = "${calc_data_dir_path}/chooseable_strategy_list_of_${prisoner_name}.txt";
    open( my $chooseable_strategy_list_fh, ">", encode( "cp932", $chooseable_strategy_list_txt_path ) );

    my $indistinguishable_coloring_list_txt_path = "${calc_data_dir_path}/indistinguishable_coloring_list_of_${prisoner_name}.txt";
    my $indistinguishable_coloring_data = read_indistinguishable_coloring_list( $indistinguishable_coloring_list_txt_path );
    open( my $all_strategy_list_fh, "<", encode( "cp932", $all_strategy_list_file_path ) );
    while( my $line = <$all_strategy_list_fh> ) {
      chomp $line;
      my ( $strategy_name, $strategy_data ) = read_function_data( $line );
      if ( is_chooseable( $indistinguishable_coloring_data, $strategy_data ) ) {
        print $chooseable_strategy_list_fh $strategy_name . "\n";
      }
    }
    close $all_strategy_list_fh;
    close $chooseable_strategy_list_fh
  }
}

sub read_indistinguishable_coloring_list {
  my ( $file_path ) = @_;
  my %data;
  open( my $fh, "<", encode( "cp932", $file_path) );
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

#------------------------------------------------------------------

sub make_predictor_list {
  my $predictor_list_file_path = "${calc_data_dir_path}/predictor_list.txt";
  my $num_of_prisoner = $setting->{"num_of_prisoner"};
  my $prisoner_list = read_list( "prisoner" );
  my $first = 1;
  my $calc_counter = 0;
  my $calc_file_path;
  foreach my $prisoner_name ( @$prisoner_list ) {
    my $chooseable_strategy_list_txt_path = "${calc_data_dir_path}/chooseable_strategy_list_of_${prisoner_name}.txt";
    if ( $first ) {

      $calc_file_path = "${calc_data_dir_path}/calc_${calc_counter}.txt";
      open( my $calc_fh, ">", encode( "cp932", $calc_file_path ) );

      open( my $chooseable_strategy_list_fh, "<", encode( "cp932", $chooseable_strategy_list_txt_path ) );
      while ( my $line = <$chooseable_strategy_list_fh> ) {
        chomp $line;
        print $calc_fh "${prisoner_name}->${line}\n";
      }
      close $chooseable_strategy_list_fh;

      close $calc_fh;
      $calc_counter++;
      $first = 0;

    } else {

      my $last_counter = $calc_counter-1;
      my $last_calc_file_path = "${calc_data_dir_path}/calc_${last_counter}.txt";
      my $now_calc_file_path = "${calc_data_dir_path}/calc_${calc_counter}.txt";
      open( my $last_calc_fh, "<", encode( "cp932", $last_calc_file_path ) );
      open( my $now_calc_fh, ">", encode( "cp932", $now_calc_file_path ) );
      while ( my $last_line = <$last_calc_fh> ) {
        chomp $last_line;
        open( my $chooseable_strategy_list_fh, "<", encode( "cp932", $chooseable_strategy_list_txt_path ) );
        while ( my $line = <$chooseable_strategy_list_fh> ) {
          chomp $line;
          print $now_calc_fh "$last_line,${prisoner_name}->${line}\n";
        }
        close $chooseable_strategy_list_fh;
      }
      close $last_calc_fh;
      unlink $last_calc_file_path;
      close $now_calc_fh;
      $calc_counter++;

      if ( $num_of_prisoner == $calc_counter ) {
        open( my $predictor_list_fh, ">", $predictor_list_file_path );
        open( my $now_calc_fh, "<", encode( "cp932", $now_calc_file_path ) );
        my $predictor_counter = 0;
        while ( my $now_line = <$now_calc_fh> ) {
          print $predictor_list_fh "P_${predictor_counter}:" . $now_line;
          $predictor_counter++;
        }
        close $now_calc_fh;
        close $predictor_list_fh;
        unlink $now_calc_file_path;
      }

    }
  }
  return $predictor_list_file_path;
}

#------------------------------------------------------------------

sub analysis_predictor {
  my ( $coloring_list_file_path, $all_strategy_list_file_path, $predictor_list_file_path ) = @_;
  my $analysis_data_file_path = "${calc_data_dir_path}/analysis_data.txt";

  my $num_of_prisoner = $setting->{"num_of_prisoner"};
  my $prisoner_list = read_list( "prisoner" );

  open( my $predictor_list_fh, "<", encode( "cp932", $predictor_list_file_path ) );
  while ( my $line = <$predictor_list_fh> ) {
    chomp $line;
    my ( $predictor_name, $predictor_data ) = read_function_data( $line );
    
  }

  close $predictor_list_fh;

  return $analysis_data_file_path;
}

#------------------------------------------------------------------

sub read_list {
  my ( $mode ) = @_;
  my $list = [];

  open( my $list_fh, "<", encode( "cp932", $setting->{"${mode}_list_file_path"} ) );
  while( my $line = <$list_fh> ) {
    chomp $line;
    push( @$list, $line );
  }
  close $list_fh;
  return $list;
}

1;
