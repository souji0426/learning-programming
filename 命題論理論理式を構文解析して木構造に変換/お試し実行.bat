ruby make_tree.rb

perl -w make_output_tex.pl

platex hoge.tex

dvipdfmx hoge.dvi

copy /Y "./hoge.pdf" "./実行結果.pdf"

del "./hoge.aux"

del "./hoge.dvi"

del "./hoge.log"

del "./hoge.pdf"

rem del "./hoge.tex"

"./実行結果.pdf"
