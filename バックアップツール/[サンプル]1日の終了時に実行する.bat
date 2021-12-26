cd C:\souji\learning-programming\バックアップツール

ruby dir_backup.rb

copy /Y "./souji.zip" "C:\Googleドライブ共有用フォルダ\zipファイルフォルダ/souji.zip"

copy /Y "./souji.zip" "D:\souji.zip"

del "./souji.zip"

xcopy "C:\souji\reference\data" "C:\Googleドライブ共有用フォルダ\文献保管フォルダ" /s/e/y/d
