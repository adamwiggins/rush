require File.dirname(__FILE__) + '/../lib/rush'

box = Rush::Box.new('fenris')
file = box['/tmp']['another']
file.write('some stuff')
puts "Wrote and read back: #{file.contents}"

