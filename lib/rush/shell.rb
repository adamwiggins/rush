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

			Readline.basic_word_break_characters = ""
			Readline.completion_append_character = nil
			Readline.completion_proc = completion_proc

			eval @config.load_env, @pure_binding

			eval "def processes; Rush::Box.new('localhost').processes; end", @pure_binding

			commands = @config.load_commands
			Rush::Dir.class_eval commands
			Array.class_eval commands
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
					puts "Exception #{e.class}: #{e}"
					e.backtrace.each do |t|
						puts "   #{::File.expand_path(t)}"
					end
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
				puts "#{res.entries.size} matching files with #{res.lines.size} matching lines"
			else
				puts "=> #{res.inspect}"
			end
		end

		def path_parts(input)
			input.match(/^(.+)\[(['"])([^\]]+)$/).to_a.slice(1, 3) rescue [ nil, nil, nil ]
		end

		def completion_proc
			proc do |input|
				possible_var, quote, partial_path = path_parts(input)
				if possible_var and possible_var.match(/^[a-z0-9_]+$/)
					full_path = eval("#{possible_var}.full_path", @pure_binding) rescue nil
					box = eval("#{possible_var}.box", @pure_binding) rescue nil
					if full_path and box
						dir = Rush::Dir.new(full_path, box)
						return dir.entries.select do |e|
							e.name.match(/^#{partial_path}/)
						end.map do |e|
							possible_var + '[' + quote + e.name + (e.dir? ? "/" : "")
						end
					end
				end
				nil
			end
		end
	end
end
