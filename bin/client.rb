require File.dirname(__FILE__) + '/../lib/rush'

box = Rush::Box.new('kvasir')
dir = box['/tmp/client_server_dir/'].create

file = dir['file_to_write']
file.write('some stuff')
file.rename('new_name')

renamed = dir['new_name']

puts "Wrote and read back: #{renamed.contents}"

subdir = dir['subdir/'].create
copied = renamed.copy_to subdir

puts "Copied to #{copied}"

dir.destroy

