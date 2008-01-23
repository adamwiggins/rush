require File.dirname(__FILE__) + '/../lib/rush'

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
		res = eval cmd

		if res.kind_of? Array
			res.each do |item|
				puts item
			end
		else
			puts "=> #{res.inspect}"
		end

	rescue Exception => e
		puts e
	end
end

