require 'open3'
require 'fileutils'
require 'net/http'
require 'uri'

#############################################################################################
# You need ResourcePatcher binary from DAVA Engine (https://github.com/dava/dava.engine)
# Compiled binary is uploaded on subdiox repository (https://github.com/subdiox/dava.engine)
#
# - Path to ResourcePatcher binary (executable format)
rp_path = "/Applications/Toolset/ResourcePatcher"
#############################################################################################


if !File.exist?("wotblitz.apk")
    puts "Downloading wotblitz.apk ..."
    command = "curl -s -L \'https://apkpure.com/world-of-tanks-blitz/net.wargaming.wot.blitz/download\' | grep id=\\\"iframe_download | cut -d\'\"\' -f4"
    o, e, s = Open3.capture3(command)

    url = o.chop
    puts "URL: " + url
    command = "wget -O wotblitz.apk \'" + url + "\'"
    Open3.pipeline(command)
    puts "Finished downloading."
end

if !File.exist?("wotblitz/assets/Data/version.txt")
    puts "Unzipping wotblitz.apk to wotblitz ..."
    command = "rm -rf wotblitz && unzip -d wotblitz wotblitz.apk"
    o, e, s = Open3.capture3(command)
    puts "Finished unzipping."
end

command = "cat wotblitz/assets/Data/version.txt | cut -d'.' -f1-3"
o, e, s = Open3.capture3(command)
version = o.chop

command = "curl \'http://dl-wotblitz-gc.wargaming.net/dlc/g" + version + ".info\'"
o, e, s = Open3.capture3(command)
patch_number = o

puts "--------------------------------"
puts "   Version: " + version
puts "   Patch Number: " + patch_number
puts "--------------------------------"

if !File.exist?("patch")
    puts "Downloading patch file ..."
    url = "http://dl-wotblitz-gc.wargaming.net/dlc/r" + patch_number + "/r0-" + patch_number + ".patch"
    command = "wget -O patch \'" + url + "\'"
    Open3.pipeline(command)
    puts "Finished downloading."
end

puts "Applying patch file ..."
command = "rm -rf Data && cp -r wotblitz/assets/Data . && cd Data && " + rp_path + " apply-all ../patch"
Open3.pipeline(command)
puts "Finished applying."
