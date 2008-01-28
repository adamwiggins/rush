require File.dirname(__FILE__) + '/../lib/rush'

box = Rush::Box.new('kvasir')
dir = box['/tmp/client_server_dir/']
dir.create
file = dir['file_to_write']
file.write('some stuff')
puts "Wrote and read back: #{file.contents}"
file.destroy
dir.destroy

