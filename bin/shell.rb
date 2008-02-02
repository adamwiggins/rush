require File.dirname(__FILE__) + '/../lib/rush'
require 'readline'

module Rush
	class Shell
		def initialize
			root = Rush::Dir.new('/')
			home = Rush::Dir.new(ENV['HOME'])
			pwd = Rush::Dir.new(ENV['PWD'])

			@pure_binding = Proc.new { }
			$last_res = nil

			@config = Rush::Config.new

			@config.load_history.each do |item|
				Readline::HISTORY.push(item)
			end

			eval @config.load_env, @pure_binding

			commands = @config.load_commands
			Rush::Dir.class_eval commands
			Array.class_eval commands
			Hash.class_eval commands
		end

		def run
			loop do
				cmd = Readline.readline('rush> ')

				finish if cmd.nil?
				next if cmd == ""
				Readline::HISTORY.push(cmd)

				begin
					res = eval(cmd, @pure_binding)
					$last_res = res
					eval("_ = $last_res", @pure_binding)
					print_result res
				rescue Exception => e
					puts e
				end
			end
		end

		def finish
			@config.save_history(Readline::HISTORY.to_a)
			puts
			exit
		end

		def print_result(res)
			if res.kind_of? String
				puts res
			elsif res.kind_of? Array
				res.each do |item|
					puts item
				end
			elsif res.kind_of? Rush::SearchResults
				widest = res.entries.map { |k| k.full_path.length }.max
				res.entries_with_lines.each do |entry, lines|
					print entry.full_path
					print ' ' * (widest - entry.full_path.length + 2)
					print "=> "
					print res.colorize(lines.first.strip.head(30))
					print "..." if lines.first.strip.length > 30
					if lines.size > 1
						print " (plus #{lines.size - 1} more matches)"
					end
					print "\n"
				end
			else
				puts "=> #{res.inspect}"
			end
		end
	end
end

Rush::Shell.new.run
