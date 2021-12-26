require "zip"

#下記のクラスは開発者のモノをそのままコピーしたもの。
#-----------------------------------------------------------------------------------------------
class ZipFileGenerator
    # Initialize with the directory to zip and the location of the output archive.
    def initialize(input_dir, output_file)
      puts input_dir
      puts output_file
        @input_dir = input_dir
        @output_file = output_file
    end

    # Zip the input directory.
    def write
        entries = Dir.entries(@input_dir) - %w(. ..)

        Zip.unicode_names = true
        ::Zip::File.open(@output_file, ::Zip::File::CREATE) do |zipfile|
            write_entries entries, '', zipfile
        end
    end

    private

    # A helper method to make the recursion work.
    def write_entries(entries, path, zipfile)
        entries.each do |e|
            zipfile_path = path == '' ? e : File.join(path, e)
            disk_file_path = File.join(@input_dir, zipfile_path)
            puts "Deflating #{disk_file_path}"

            if File.directory? disk_file_path
                recursively_deflate_directory(disk_file_path, zipfile, zipfile_path)
            else
                put_into_archive(disk_file_path, zipfile, zipfile_path)
            end
        end
    end

    def recursively_deflate_directory(disk_file_path, zipfile, zipfile_path)
      #FileUtils.mkdir_p( zipfile_path.encode('cp932') ) unless FileTest.exist?( zipfile_path.encode('cp932') )
      zipfile.mkdir zipfile_path.encode('cp932')
        subdir = Dir.entries(disk_file_path) - %w(. ..)
        write_entries subdir, zipfile_path, zipfile
    end

    def put_into_archive(disk_file_path, zipfile, zipfile_path)
        zipfile.get_output_stream(zipfile_path.encode('cp932')) do |f|
            #f.write(File.open(disk_file_path, 'rb').read)
            IO.copy_stream(File.open(disk_file_path, 'rb'), f)
        end
    end
end
#-----------------------------------------------------------------------------------------------

start_time = Time.now
puts "soujiフォルダの圧縮開始";

zip_file_generator = ZipFileGenerator.new( "C:\\souji\\", ".\\souji.zip")
zip_file_generator.write

puts "soujiフォルダの圧縮完了";
puts "経過秒数(整数)：#{Time.now - start_time}"
