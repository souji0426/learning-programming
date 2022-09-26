ruby make_tree.rb

perl -w make_output_tex.pl

platex hoge.tex

dvipdfmx hoge.dvi

copy /Y "./hoge.pdf" "./é¿çsåãâ .pdf"

del "./hoge.aux"

del "./hoge.dvi"

del "./hoge.log"

del "./hoge.pdf"

rem del "./hoge.tex"

"./é¿çsåãâ .pdf"
