class Rush::SshTunnel
	def initialize(real_host)
		@real_host = real_host
		@port
	end

	def host
		'localhost'
	end

	def port
		ensure_tunnel
		@port
	end

	def ensure_tunnel
		return if @port

		if config.tunnels[host]
			@port = config.tunnels[host]
		else
			push_credentials
			establish_tunnel
		end
	end

	class SshFailed < Exception; end

	def push_credentials
		config.ensure_credentials_exist
		raise SshFailed unless ssh_append_to_credentials(config.credentials_file.contents.strip)
	end

	def ssh_append_to_credentials(string)
		# the following horror is exactly why rush is needed
		passwords_file = "~/.rush/passwords"
		string = "'#{string}'"
		command = "M=`grep #{string} #{passwords_file} | wc -l`; if [ $M = 0 ]; then echo #{string} >> #{passwords_file}; fi"
		system "ssh #{@real_host} '#{command}'"
	end

	def establish_tunnel
		display "Establishing an ssh tunnel to #{@real_host}..."
		@port = next_available_port

		make_ssh_tunnel(:local_port => port, :remote_port => Rush::Config::DefaultPort, :ssh_host => @real_host, :stall_command => "sleep 9000")

		tunnels = config.tunnels
		tunnels[@real_host] = port
		config.save_tunnels tunnels

		sleep 0.5
	end

	def make_ssh_tunnel(options)
		raise SshFailed unless system(bash_ssh_command(options))
	end

	def bash_ssh_command(options)
		"ssh -L #{options[:local_port]}:127.0.0.1:#{options[:remote_port]} #{options[:ssh_host]} '#{options[:stall_command]}' &"
	end

	def next_available_port
		(config.tunnels.values.max || Rush::Config::DefaultPort) + 1
	end

	def config
		@config ||= Rush::Config.new
	end

	def display(msg)
		puts msg
	end
end
