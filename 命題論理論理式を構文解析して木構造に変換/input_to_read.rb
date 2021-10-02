# -*- encoding: utf-8 -*-
require "inifile"
require "fileutils"
#ファイル操作に必要
require "rubyXL"
require "rubyXL/convenience_methods"
#xlsxに書き込むために使用

require "./Common_method.rb"
include Common_method

def main
  ini = IniFile.load( "./setting.ini" )

  data_in_input_xlsx = Common_method.read_input_xlsx( ini )
  data_in_read_xlsx = Common_method.read_read_xlsx( ini, data_in_input_xlsx )
  new_data_in_input_xlsx = Common_method.get_new_data( data_in_input_xlsx, data_in_read_xlsx )

  #新規登録がなければ何もしない
  if !new_data_in_input_xlsx.empty? then

    data_hash_for_output = make_data_for_output( ini, data_in_input_xlsx, data_in_read_xlsx )

    reference_dir_path =  ini["common"]["reference_dir_path"]
    new_read_xlsx_path = reference_dir_path + "新文献情報閲覧用.xlsx"
    output_data( ini, new_read_xlsx_path, data_hash_for_output  )

    #ここに見栄えを整える関数を入れたい
    edit_the_formatting( new_read_xlsx_path, new_data_in_input_xlsx )

    old_read_xlsx_path = ini["common"]["read_xlsx"]
    FileUtils.cp( new_read_xlsx_path, old_read_xlsx_path + ".backup" )
    #初回実行時はこのファイルは存在しないので、存在するときだけ古い方のファイルを削除
    if File.exist?( old_read_xlsx_path ) then
      FileUtils.rm( old_read_xlsx_path )
    end

    FileUtils.cp( new_read_xlsx_path, old_read_xlsx_path )
    FileUtils.rm( new_read_xlsx_path )
  end

end

def make_data_for_output( ini, input_data_hash, read_data_hash )
  data = Hash.new
  input_data_hash.each_key { |tag_name|
    if data[tag_name].nil? then
      data[tag_name] = Hash.new
    end

    input_data_hash[tag_name].each_key { |tag_num|

      if read_data_hash.has_key?( tag_name ) and read_data_hash[tag_name].has_key?( tag_num )
        data[tag_name][tag_num] = read_data_hash[tag_name][tag_num]

      else
        item_array = ini["item_of_read_xlsx"].keys
        data[tag_name][tag_num] = Hash.new

        tag = "#{tag_name}#{format( "%03d", tag_num )}"
        for i in 2..item_array.length-1 do
          item = item_array[i]

          if item == "status" then
            data[tag_name][tag_num][item] = "未読"

          elsif item == "file_path" then
            file_exist = false
            target_dir = "#{File.expand_path( ini["common"]["data_dir"] )}/#{tag_name}/"
            Dir.glob( "#{File.expand_path( target_dir )}/*#{tag}*.*" ).each { |file_path|
              data[tag_name][tag_num][item] = file_path
              file_exist = true
            }
            if !file_exist then
              data[tag_name][tag_num][item] = " "
            end

          elsif item == "explanatory_text_tex_path" or item == "thoughts_tex_path" then
            dir_path = ini["common"]["reference_dir_path"]
            target_dir = "#{dir_path}/#{item.sub( /_tex_path/, "")}/#{tag_name}"
            file_name = "#{tag}.tex"
            file_path = "#{File.expand_path( target_dir )}/#{file_name}"
            data[tag_name][tag_num][item] = file_path

          else
            if input_data_hash[tag_name][tag_num][item] == "null" then
              data[tag_name][tag_num][item] = " "
            else
              data[tag_name][tag_num][item] = input_data_hash[tag_name][tag_num][item]
            end
          end
      end
    end
    }
  }

  return data
end

def output_data( ini, xlsx_path, data_hash )
  book = RubyXL::Workbook.new

  make_sheet_and_input_header( ini, book, data_hash )

  data_hash.each_key { |tag_name|
    data_hash[tag_name].each_key { |tag_num|
      output_one_data( ini, book, data_hash, tag_name, tag_num )
    }
  }

  book.write( xlsx_path )
end

def make_sheet_and_input_header( ini, book, data_hash )
  data_hash.each_key { |tag|
    sheet = book.add_worksheet( tag )
    header_item_name_array = ini["item_of_read_xlsx"].values

    for i in 0..header_item_name_array.length do
      sheet.add_cell( 0, i, header_item_name_array[i] )
    end
  }
  #Sheet1がいらないので消す
  book.worksheets.delete_at( 0 )
end

def output_one_data( ini, book, hash, tag_name, tag_num )
  item_array = ini["item_of_read_xlsx"].keys

  book[tag_name].add_cell( tag_num, 0, tag_name )
  book[tag_name].add_cell( tag_num, 1, tag_num )
  #ここから書き込むが、特定の項目では処理が異なる

  for i in 2..item_array.length-1 do
    item = item_array[i]
    data = hash[tag_name][tag_num][item]

    #url系・ファイルパス系項目は記入があればハイパーリンクを入れて書き込む
    hyper_link_item = [
      "url", "amazon_url", "file_path", "explanatory_text_tex_path", "thoughts_tex_path"
    ]
    if hyper_link_item.include?( item ) then
      if data == " "  then
        book[tag_name].add_cell( tag_num, i, " " )
      else
        link = %Q{HYPERLINK( "#{data}", "#{data}" ) }
        book[tag_name].add_cell( tag_num, i, data, link )
      end
    else
      book[tag_name].add_cell( tag_num, i, data )
    end

  end
end

def edit_the_formatting( new_read_xlsx_path, new_data_hash )
  book = RubyXL::Parser.parse( new_read_xlsx_path )

  #新規登録された情報を分かりやすくするために、該当するセルに色をつける
  new_data_hash.each_key { |tag_name|
    new_data_hash[tag_name].each_key { |tag_num|
      sheet = book[tag_name]
      row = tag_num
      sheet.change_row_fill( row, "ffff00" ) 
    }
  }

  book.write( new_read_xlsx_path )
end

main()
