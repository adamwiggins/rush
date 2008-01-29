require File.dirname(__FILE__) + '/../lib/rush'
require 'readline'

def print_result(res)
	if res.kind_of? String
		puts res
	elsif res.kind_of? Array
		res.each do |item|
			puts item
		end
	elsif res.kind_of? Hash
		widest = res.keys.map { |k| k.name.length }.max
		res.each do |key, value|
			print key.name
			print ' ' * (widest - key.name.length + 2)
			print "=> "
			print value.inspect
			print "\n"
		end
	else
		puts "=> #{res.inspect}"
	end
end

root = Rush::Dir.new('/')
home = Rush::Dir.new(ENV['HOME'])
pwd = Rush::Dir.new(ENV['PWD'])

def mate(*args)
	system "mate #{args.join(' ' )}"
end

def vi(*args)
	system "vi #{args.join(' ')}"
end

def rake(*args)
	system "rake #{args.join(' ')}"
end

pure_binding = Proc.new { }
$last_res = nil

config = Rush::Config.new

config.load_history.each do |item|
	Readline::HISTORY.push(item)
end

eval config.load_env, pure_binding

loop do
	cmd = Readline.readline('rush> ')

	if cmd.nil?
		config.save_history(Readline::HISTORY.to_a)
		puts
		exit
	end

	next if cmd == ""

	Readline::HISTORY.push(cmd)

	begin
		res = eval(cmd, pure_binding)
		$last_res = res
		eval("_ = $last_res", pure_binding)
		print_result res
	rescue Exception => e
		puts e
	end
end

