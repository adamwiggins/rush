require File.dirname(__FILE__) + '/../lib/rush'

def print_result(res)
	if res.kind_of? String
		puts res
	elsif res.kind_of? Array
		res.each do |item|
			puts item
		end
	else
		puts "=> #{res.inspect}"
	end
end

root = Rush::Dir.new('/')
home = Rush::Dir.new(ENV['HOME'])
pwd = Rush::Dir.new(ENV['PWD'])

loop do
	print "rush> "
	cmd = gets

	if cmd.nil?
		puts
		exit
	end

	begin
		print_result eval(cmd)
	rescue Exception => e
		puts e
	end
end

