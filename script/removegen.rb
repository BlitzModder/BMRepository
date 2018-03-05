require 'rubygems'
require 'rbconfig'
require 'fileutils'
require 'digest'
require 'csv'
require 'archive/zip'

if !File.exist?("Data")
    puts "[Error] 'Data' directory does not exist in the current directory."
    exit
end

if !File.exist?("../install")
    puts "[Error] 'install' directory does not exist in the parent directory."
    exit
end

puts "[#] This script generates removal files from original Data and installation files."

if File.exist?("../.tmp")
    FileUtils.rm_rf("../.tmp")
end
FileUtils.mkdir_p("../.tmp/install")
FileUtils.mkdir_p("../.tmp/remove")

checksums_file = 'checksums.csv'
checksums = []
if File.exists?(checksums_file)
    checksums = CSV.read(checksums_file)
end

str = ""
Dir.glob("../install/*.zip").sort.each do |install_zip_path|
    install_zip_file = File.basename(install_zip_path)
    
    last_str = str
    str = "[#] Processing #{install_zip_file} ..."
    diff = last_str.length - str.length
    if diff < 0 then
        diff = 0
    end
    print(str + " " * diff + "\r")
    STDOUT.flush

    checksum = Digest::MD5.file(install_zip_path).hexdigest
    search_result = checksums.select{ |c| c[0] == install_zip_file }
    if search_result.count == 0 then
        checksums.push([install_zip_file, checksum])
    elsif search_result.count == 1 then
        if search_result[0][1] == checksum then
            next
        end
    else
        checksums.keep_if{ |c| c[0] == install_zip_file }
        checksums.push([install_zip_file, checksum])
    end

    Archive::Zip.extract(install_zip_path, "../.tmp/install")
    if Dir.glob("../.tmp/install/*").map{|path| File.basename(path)}.include?("Data") then
        Dir.glob("../.tmp/install/Data/**/*").each do |install_path|
            if File::ftype(install_path) != "directory"
                data_file = install_path.gsub("\.\./\.tmp/install/", "")
                remove_path = install_path.gsub("\.\./\.tmp/install/", "\.\./\.tmp/remove/")
                remove_dir = File.dirname(remove_path)
		if !File.exist?(remove_dir)
                    FileUtils.mkdir_p(remove_dir)
                end
                if File.exist?(data_file)
                    FileUtils.copy(data_file, remove_path)
                end
            end
        end
        remove_zip_path = install_zip_path.gsub("\.\./install/", "\.\./remove/")
        Archive::Zip.archive(remove_zip_path, "../.tmp/remove/Data")
        FileUtils.rm_rf(Dir.glob("../.tmp/install/*"))
        FileUtils.rm_rf(Dir.glob("../.tmp/remove/*"))
    else
        FileUtils.rm_rf("../.tmp/")
        puts "[Error] Data directory is not included in #{install_zip_file}"
        exit
    end
end
FileUtils.rm_rf("../.tmp/")
CSV.open(checksums_file, 'w') do |c_f|
    checksums.sort.each do |c|
        c_f << c
    end
end
puts "[#] Completed generating remove directory."
