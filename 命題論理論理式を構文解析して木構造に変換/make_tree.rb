require "fileutils"

def main
  #入力ファイルの読み込み
  input_file_path = "./input.txt"
  #入力ファイルの各行（に書かれているTeX形式の論理式）を配列に格納して返す
  #そのさい見栄えのために論理式に含まれている空白スペースを削除する
  expression_list = read_text( input_file_path )

  #出力ファイルがすでにあれば削除しておく
  output_file_path = "./output.txt"
  if FileTest.exists?( output_file_path ) then
    FileUtils.rm( output_file_path )
  end


  for expression in expression_list do

    #TeX形式の論理式を構文解析して木構造にして返す
    #返り値のtreeは木構造とは名ばかりの1次元配列
    #各キーは「a-b-…-c」という数字のハイフンつなぎ形式で、数字は0,1のどちらか
    #このキーで二分木の高さと位置を表現している
    #バリューはTeX形式の論理式
    tree = analyze_expression( expression )

    #見やすさのために再度空白スペースをtreeの全ての論理式に挿入する
    #具体的には論理結合子の前後と左括弧の直後・右括弧の直前に「\ 」を挿入する
    insert_space_in_all_expression( tree )

    output_tree( tree, output_file_path )
  end
end

#read_text関連関数--------------------------------------------------------------------------------

def read_text( input_file_path )
  expression_list = []
  File.readlines( input_file_path ).each do |line|
    line = line.chomp
    line = line.gsub( "\\\s", "" )
    line = line.gsub( "\s", "" )
    expression_list.push( line )
  end
  return expression_list
end

#---------------------------------------------------------------------------------------------------

#analyze_expression関連関数---------------------------------------------------------------------

def get_sub_expression( expression, num )
  target_expression = expression[1..expression.length-2]
  if num == 1 then
    return expression[6..expression.length-2]
  elsif num == 2
    left_expression = ""
    right_expression = ""
    right_expression_start = 0
    formula_building_operation_start = 0
    if target_expression =~ /\AA_[0-9]{1}/ then
      left_expression = target_expression.slice( 0..2 )
      formula_building_operation_start = 3
    elsif target_expression =~ /\A\(/ then
      num_of_left_parenthesis = 0
      num_of_right_prarenthesis = 0
      while num_of_right_prarenthesis == 0 or num_of_left_parenthesis != num_of_right_prarenthesis do
        target_symbol = target_expression.slice( formula_building_operation_start )
        if target_symbol == "\(" then
          num_of_left_parenthesis += 1
        elsif target_symbol == "\)" then
          num_of_right_prarenthesis += 1
        end
        left_expression += target_symbol
        formula_building_operation_start += 1
      end
    end
    operation_and_right_expression = target_expression.slice( formula_building_operation_start..target_expression.length-1 )
    if operation_and_right_expression =~ /\A\\land/ then
      right_expression_start = formula_building_operation_start + 5
    elsif operation_and_right_expression =~ /\A\\lor/ then
      right_expression_start = formula_building_operation_start + 4
    elsif operation_and_right_expression =~ /\A\\to/ then
      right_expression_start = formula_building_operation_start + 3
    elsif operation_and_right_expression =~ /\A\\leftrightarrow/ then
      right_expression_start = formula_building_operation_start + 15
    end
    right_expression = target_expression.slice( right_expression_start..target_expression.length-1 )
    return left_expression, right_expression
  end
end

def is_finish( tree, num )
  tree.each{ |key, value|
    if key.length == num * 2 - 1 then
      if tree[key] =~ /\A\(/ then
        return false
      end
    end
  }
  return true
end

def make_tree( target_expression, tree, height )
  for num in 1..height do
    if is_finish( tree, num ) then
      break
    end
    result_hash = {}
    tree.each{ |key, value|
      if key.length == num * 2 - 1 then
        if value =~ /\A\(\\lnot/ then
          result_hash[ key + "-0" ] = get_sub_expression( value, 1 )
        elsif value =~ /\A\(\(|\(A_[0-9]{1}/ then
          sub_expression_one, sub_expression_two = get_sub_expression( value, 2 )
          result_hash[ key + "-0" ] = sub_expression_one
          result_hash[ key + "-1" ] = sub_expression_two
        end
      end
    }
    result_hash.each{ |key, value|
      tree[key] = value
    }
  end
  tree.each{ |key, value|
    if value == "" then
      tree.delete( key )
    end
  }
end

def make_skeleton_tree( tree, height )
  for num in 1..height do
    target_keys = []
    tree.each{ |key, value|
      if key.length == num * 2 - 1 then
        target_keys.push( key )
      end
    }
    for key in target_keys do
      tree[ key + "-0" ] = ""
      tree[ key + "-1" ] = ""
    end
  end
end

def analyze_expression( expression )
  tree = { "0" => expression }
  max_height_of_tree = expression.scan(/\(/).size + 1
  make_skeleton_tree( tree, max_height_of_tree )
  make_tree( expression, tree, max_height_of_tree )
  return tree
end

#---------------------------------------------------------------------------------------------------

#insert_space_in_all_expression関連関数--------------------------------------------------------

def insert_space_in_all_expression( tree )
  tree.each{ |key, expression|
    if expression.scan( /\(/ ).size > 0 then
      expression.gsub!( "\(", "\(\s" )
      expression.gsub!( "\)", "\s\)" )
      expression.gsub!( "\\lnot", "\\lnot\s" )
      expression.gsub!( "\\land", "\s\\land\s" )
      expression.gsub!( "\\lor", "\s\\lor\s" )
      expression.gsub!( "\\to", "\s\\to\s" )
      expression.gsub!( "\\leftrightarrow", "\s\\leftrightarrow\s" )
      tree[key] = expression
    end
  }
end

#---------------------------------------------------------------------------------------------------

#output_tree関連関数-----------------------------------------------------------------------------

def get_num_of_child( tree, node_name )
  child_counter = 0
  tree.each{ |key, value|
    if key =~ /\A#{node_name}/ and key != node_name and key != node_name + "l" and key != node_name + "r" then
      child_counter += 1
    end
  }
  return child_counter
end

def get_start_position( list )
  for num in 0..(list.size - 1) do
    if list[ num ] == "" then
      return num
    end
  end
end

def get_same_height_keys( tree, num )
  result_keys = []
  tree.each{ |key, value|
    if num == ( key.length + 1 ) / 2 then
      result_keys.push( key )
    end
  }
  return result_keys
end

def kill_all_dummy_child( list )
  for num in 0..(list.size - 1) do
    if list[ num ] =~ /dummy child\Z/ then
      list[ num ] = ""
    end
  end
end

def put_tree_in_order_and_make_sentense( tree, for_output_tree )
  list = Array.new( for_output_tree.size, "" )
  height = get_tree_height( tree )
  for num in 1..height do
    kill_all_dummy_child( list )
    for key in get_same_height_keys( tree, num ) do
      if for_output_tree.has_key?( key + "l" ) then
        if key == "0" then
          list[ get_start_position(list) ] = "\t" * ( num ) + "\\Tree ["
        else
          list[ get_start_position(list) ] = "\t" * ( num ) + "["
        end
        list[ get_start_position(list) ] = "\t" * ( num ) + ".{$" + tree[ key ] + "$}"
        num_of_child = get_num_of_child( for_output_tree, key )
        for i in 1..num_of_child do
          list[ get_start_position(list) ] = "\t" * ( num ) + "dummy child"
        end
        list[ get_start_position(list) ] = "\t" * ( num ) + "]"
      else
        list[ get_start_position(list) ] = "\t" * ( num ) + "{$" + tree[ key ] + "$}"
      end
    end
  end
  return list
end

def copy_tree_to_skeleton( tree, skeleton_tree )
  skeleton_tree.each{ |key, value|
    if tree.has_key?( key ) then
      skeleton_tree[ key ] = tree[ key ]
      if !tree.has_key?( key + "-0" ) then
        skeleton_tree.delete( key + "l" )
        skeleton_tree.delete( key + "r" )
      end
    else
      skeleton_tree.delete( key + "l" )
      skeleton_tree.delete( key + "r" )
      if key !~ /l|r\Z/ then
        skeleton_tree.delete( key )
      end
    end
  }
  return skeleton_tree
end

def make_skeleton_for_output_tree( height )
  tree = { "0" => "" }
  for num in 1..height do
    target_keys = []
    tree.each{ |key, value|
      if key.length == num * 2 - 1 then
        target_keys.push( key )
      end
    }
    for key in target_keys do
      tree[ key + "-0" ] = ""
      tree[ key + "-1" ] = ""
      tree[ key + "l" ] = ""
      tree[ key + "r" ] = ""
    end
  end
  return tree
end

def get_tree_height( tree )
  max = 0
  tree.each{ |key, value|
    height = ( key.length + 1 ) / 2
    if max < height then
      max = height
    end
  }
  return max
end

def make_sentence_for_output( tree )
  height = get_tree_height( tree )
  skeleton_tree = make_skeleton_for_output_tree( height )
  for_output_tree = copy_tree_to_skeleton( tree, skeleton_tree )
  return put_tree_in_order_and_make_sentense( tree, for_output_tree )
end

def output_tree( tree, output_file_path )
  sentence_list = make_sentence_for_output( tree )
  File.open( output_file_path, mode = "a" ){ |f|
    f.write( "---------$" + tree["0"] + "$のtree図---------\n\n" )
    f.write( "\\begin{center}\n" )
    f.write( "\t\\begin{tikzpicture}[\n" )
    f.write( "\t\t\%grow=right,\n" )
    f.write( "\t\tlevel distance=50pt,\n" )
    f.write( "\t\tsibling distance=20pt,\n" )
    f.write( "\t\tevery tree node/.style={anchor=north},\n" )
    f.write( "\t\tevery node/.append style={align=center}\n" )
    f.write( "\t]\n" )
    for num in 0..(sentence_list.size - 1) do
      f.write( sentence_list[num] + "\n" )
    end
    f.write( "\t\\end{tikzpicture}\n" )
    f.write( "\\end{center}\n" )
    f.write( "" )
    f.write( "\n" )
  }
end

#---------------------------------------------------------------------------------------------------


main()
