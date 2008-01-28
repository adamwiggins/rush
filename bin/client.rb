require File.dirname(__FILE__) + '/../lib/rush'

box = Rush::Box.new('fenris')
box.write_file("/tmp/another", "some stuff\n")

