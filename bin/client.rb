require File.dirname(__FILE__) + '/../lib/rush'

system "rm -rf /tmp/client_server_dir"

local = Rush::Box.new('localhost')
remote = Rush::Box.new('kvasir')
dir = remote['/tmp/client_server_dir/'].create

file = dir['file_to_write']
file.write('some stuff')
file.rename('new_name')

renamed = dir['new_name']

puts "Wrote and read back: #{renamed.contents}"

subdir = dir['subdir/'].create
copied = renamed.copy_to subdir

puts "Copied to #{copied}"

remote_dir = dir
local_dir = local['/home/adam/junk/']

remote_file = remote_dir['another_file']
remote_file.write('copy me')
local_file = remote_file.copy_to(local_dir)
puts "Contents of file copied from remote to local: #{local_file.contents}"

dir.destroy

