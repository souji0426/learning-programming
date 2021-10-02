use strict;
use warnings;
use utf8;
use Encode;

main();

sub main {

  my $output_tex_path = "./hoge.tex";
  open( my $output_fh, ">", $output_tex_path );

  print $output_fh "\\documentclass\[a4j,dvipdfmx,10pt\]\{jarticle\}\n";
  print $output_fh "\\usepackage\{tikz-qtree\}\n";
  print $output_fh "\\begin\{document\}\n";

  my $input_file_path = "./output.txt";
  open( my $input_fh, "<", $input_file_path );
  while( my $line = <$input_fh> ) {
    print $output_fh $line;
  }

  close $input_fh;


  print $output_fh "\\end\{document\}\n";
  close $output_fh;
}


1;
