use strict;
use warnings;
use utf8;
use Encode;
use Config::Tiny;
use File::Copy;
use File::Path;
use Data::Dumper;

my $num_of_check = $ARGV[0];

my $data = read_data_csv();

my $prime_num_counter = 0;
my $kaiten_prime_num_counter = 0;
my @result;
for( my $i = 2; $i <= $num_of_check; $i++ ) {
  if( is_prime( $i ) ) {
    print "${i}\n";
    $prime_num_counter++;
    my $keta = get_keta( $i );

    if( is_target( $i, $keta, $data ) ) {
      
      my $kaitengo_num = kaiten( $i, $keta, $data );
      if ( is_prime( $kaitengo_num ) ) {
        $kaiten_prime_num_counter++;
        push( @result, $i );
        print encode( "cp932", "${i}は素数で、180度回転すれば${kaitengo_num}となり${kaitengo_num}は素数である\n" );
      } else {
        print encode( "cp932", "${i}は素数で、180度回転すれば${kaitengo_num}となるが${kaitengo_num}は素数でない\n" );
      }

    } else {
      print encode( "cp932", "${i}は素数だが180度回転したら数にはならない\n" );
    }
  } else {
    print encode( "cp932", "${i}は素数でない\n" );
  }
}
print "\n--------\n";
print encode( "cp932", "${num_of_check}までの回転素数の数は${kaiten_prime_num_counter}個で以下がそのリスト\n" );
print Dumper \@result;

sub read_data_csv {
  my %data;
  open( my $fh, "<", "./data.csv" );
  while( my $line = <$fh> ) {
    chomp $line;
    my @data_in_one_line = split( ",", $line );
    my $target_num = $data_in_one_line[0];
    my $kaiten_ok = $data_in_one_line[1];
    my $num_of_kaitengo = $data_in_one_line[2];
    $data{$target_num} = { "kaiten_ok" => $kaiten_ok, "num_of_kaitengo" => $num_of_kaitengo };
  }
  close $fh;
  return \%data;
}

sub is_prime {
  my ( $num ) = @_;
  my $is_prime = 1;
  for( my $i = 2; $i <= int( sqrt( $num ) ); $i++ ) {
    if ( $num % $i == 0 ) {
      $is_prime = 0;
    }
  }
  return $is_prime;
}

sub get_keta {
  my ( $num ) = @_;
  my $keta = 1;
  while( 1 ) {
    if( int( $num / ( 10 ** $keta ) ) != 0 ) {
      $keta++;
    } else {
      last;
    }
  }
  return $keta;
}

sub is_target {
  my ( $num, $keta, $data ) = @_;
  my $is_target = 1;
  for( my $i = 0; $i <= $keta-1; $i++ ) {
    my $target_num = int ( $num / ( 10 ** ( $keta-1-$i ) ) );
    if( $data->{$target_num}->{"kaiten_ok"} ) {
      $num = $num - ( $target_num * ( 10 ** ( $keta-1-$i ) ) );
    } else {
      $is_target = 0;
      last;
    }
  }
  return $is_target;
}

sub kaiten {
  my ( $num, $keta, $data ) = @_;
  my $kaitengo_num = 0;
  for( my $i = 0; $i <= $keta-1; $i++ ) {
    my $target_num = int ( $num / ( 10 ** ( $keta-1-$i ) ) );
    my $num_of_kaitengo = $data->{$target_num}->{"num_of_kaitengo"};
    $kaitengo_num = $kaitengo_num + ( $num_of_kaitengo * ( 10 ** $i ) );
    $num = $num - ( $target_num * ( 10 ** ( $keta-1-$i ) ) );
  }
  return $kaitengo_num;
}