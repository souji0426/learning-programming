# learning-programming
プログラミングの勉強のため作ったものをまとめています。

## バックアップツール
フォルダの保存・バックアップという作業を自動したかったので作った。


## 命題論理論理式を構文解析して木構造に変換
不完全性定理の勉強会（そのノートは[ここ](https://github.com/souji0426/note-Enderton/blob/master/%E8%A3%8F%E9%9B%A3%E6%B3%A2%E5%A4%A7%E5%AD%B8%E4%B8%8D%E5%AE%8C%E5%85%A8%E6%80%A7%E5%AE%9A%E7%90%86%E5%8B%89%E5%BC%B7%E4%BC%9A%E3%83%8E%E3%83%BC%E3%83%88.pdf)）にて、命題論理の構文解析について学んだときに、それをプログラミングで実践してみた。

### 使い方
- 入力ファイルを作成する。ファイル名はinput.txt固定。
各行に命題論理の論理式を各行に1つずつ書く（いくつ書いてもいい）
ただし命題変数として使えるのは「A_[1桁数字]」のみ。
[サンプル入力ファイル](https://github.com/souji0426/learning-programming/blob/main/%E5%91%BD%E9%A1%8C%E8%AB%96%E7%90%86%E8%AB%96%E7%90%86%E5%BC%8F%E3%82%92%E6%A7%8B%E6%96%87%E8%A7%A3%E6%9E%90%E3%81%97%E3%81%A6%E6%9C%A8%E6%A7%8B%E9%80%A0%E3%81%AB%E5%A4%89%E6%8F%9B/%5Bsample%5Dinput.txt)も参考に。

- make_tree.rbを実行する
実行コマンドは「ruby make_tree.rb」
これで入力ファイルにあった全ての論理式を構文解析して、
出力ファイル（名前はoutput.txt固定）に、LaTeXTikz-qtreeパッケージの形式にあわせて、全て出力してくれる。
[サンプル入力ファイル](https://github.com/souji0426/learning-programming/blob/main/%E5%91%BD%E9%A1%8C%E8%AB%96%E7%90%86%E8%AB%96%E7%90%86%E5%BC%8F%E3%82%92%E6%A7%8B%E6%96%87%E8%A7%A3%E6%9E%90%E3%81%97%E3%81%A6%E6%9C%A8%E6%A7%8B%E9%80%A0%E3%81%AB%E5%A4%89%E6%8F%9B/%5Bsample%5Dinput.txt)を入力に実行した結果は、
[サンプル出力ファイル](https://github.com/souji0426/learning-programming/blob/main/%E5%91%BD%E9%A1%8C%E8%AB%96%E7%90%86%E8%AB%96%E7%90%86%E5%BC%8F%E3%82%92%E6%A7%8B%E6%96%87%E8%A7%A3%E6%9E%90%E3%81%97%E3%81%A6%E6%9C%A8%E6%A7%8B%E9%80%A0%E3%81%AB%E5%A4%89%E6%8F%9B/%5Bsample%5Doutput.txt)になる。


- TeXに貼り付けて使う
あとは使いたい論理式は自身のTeXファイルに貼り付けて使う。
ただしプリアンブルには最低限以下のものが必要。

```
\documentclass[a4j,dvipdfmx,10pt]{jarticle}
%jbookとかでも可
\usepackage{tikz-qtree}
```

### お試しツールの使い方
単にinputファイルの結果をさらっと見たい場合には、使い方にある通りinput.txtを用意して、
[お試し実行.bat](https://github.com/souji0426/learning-programming/blob/main/%E5%91%BD%E9%A1%8C%E8%AB%96%E7%90%86%E8%AB%96%E7%90%86%E5%BC%8F%E3%82%92%E6%A7%8B%E6%96%87%E8%A7%A3%E6%9E%90%E3%81%97%E3%81%A6%E6%9C%A8%E6%A7%8B%E9%80%A0%E3%81%AB%E5%A4%89%E6%8F%9B/%E3%81%8A%E8%A9%A6%E3%81%97%E5%AE%9F%E8%A1%8C.bat)をダブルクリックすれば、
input.txtにある論理式全てをコンパイルしてPDFにして出力してくれる。
例えば[サンプル入力ファイル](https://github.com/souji0426/learning-programming/blob/main/%E5%91%BD%E9%A1%8C%E8%AB%96%E7%90%86%E8%AB%96%E7%90%86%E5%BC%8F%E3%82%92%E6%A7%8B%E6%96%87%E8%A7%A3%E6%9E%90%E3%81%97%E3%81%A6%E6%9C%A8%E6%A7%8B%E9%80%A0%E3%81%AB%E5%A4%89%E6%8F%9B/%5Bsample%5Dinput.txt)を入力に実行した結果は、
[これ](https://github.com/souji0426/learning-programming/blob/main/%E5%91%BD%E9%A1%8C%E8%AB%96%E7%90%86%E8%AB%96%E7%90%86%E5%BC%8F%E3%82%92%E6%A7%8B%E6%96%87%E8%A7%A3%E6%9E%90%E3%81%97%E3%81%A6%E6%9C%A8%E6%A7%8B%E9%80%A0%E3%81%AB%E5%A4%89%E6%8F%9B/%5Bsample%5D%E5%AE%9F%E8%A1%8C%E7%B5%90%E6%9E%9C.pdf)になる。

make_output_tex.plはこのバッチファイルの中でoutput.txtからTeXファイルを作ってくれるプログラム。
