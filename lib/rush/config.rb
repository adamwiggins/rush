class Rush::Config
	DefaultPort = 7770

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
		passwords_file.lines_or_empty.each do |line|
			user, password = line.split(":", 2)
			hash[user] = password
		end
		hash
	end

	def credentials_file
		dir['credentials']
	end

	def credentials
		credentials_file.lines.first.split(":", 2)
	end

	def save_credentials(user, password)
		credentials_file.write("#{user}:#{password}\n")
	end

	def credentials_user
		credentials[0]
	end

	def credentials_password
		credentials[1]
	end

	def ensure_credentials_exist
		generate_credentials if credentials_file.contents_or_blank == ""
	end

	def generate_credentials
		save_credentials(generate_user, generate_password)
	end

	def generate_user
		generate_secret(4, 8)
	end

	def generate_password
		generate_secret(8, 15)
	end

	def generate_secret(min, max)
		chars = self.secret_characters
		len = rand(max - min + 1) + min
		password = ""
		len.times do |index|
			password += chars[rand(chars.length)]
		end
		password
	end

	def secret_characters
		[ ('a'..'z'), ('1'..'9') ].inject([]) do |chars, range|
			chars += range.to_a
		end
	end

	def tunnels_file
		dir['tunnels']
	end

	def tunnels
		tunnels_file.lines_or_empty.inject({}) do |hash, line|
			host, port = line.split(':', 2)
			hash[host] = port.to_i
			hash
		end
	end

	def save_tunnels(hash)
		string = ""
		hash.each do |host, port|
			string += "#{host}:#{port}\n"
		end
		tunnels_file.write string
	end
end
