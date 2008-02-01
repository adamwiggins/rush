module Rush
	class Config
		attr_reader :dir

		def initialize(location=nil)
			@dir = Rush::Dir.new(location || "#{ENV['HOME']}/.rush")
			@dir.create
		end

		def history_file
			dir['history']
		end

		def save_history(array)
			history_file.write(array.join("\n") + "\n")
		end

		def load_history
			history_file.contents_or_blank.split("\n")
		end

		def env_file
			dir['env.rb']
		end

		def load_env
			env_file.contents_or_blank
		end

		def commands_file
			dir['commands.rb']
		end

		def load_commands
			commands_file.contents_or_blank
		end

		def passwords_file
			dir['passwords']
		end

		def passwords
			hash = {}
			passwords_file.contents_or_blank.split("\n").each do |line|
				user, password = line.split(":", 2)
				hash[user] = password
			end
			hash
		end

		def credentials_file
			dir['credentials']
		end

		def credentials
			credentials_file.contents.split("\n").first.split(":", 2)
		end

		def credentials_user
			credentials[0]
		end

		def credentials_password
			credentials[1]
		end
	end
end
