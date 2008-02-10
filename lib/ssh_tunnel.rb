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
		if @port
			ensure_still_alive
			return
		end

		if config.tunnels[@real_host]
			@port = config.tunnels[@real_host]
			ensure_still_alive
		else
			setup_everything
		end
	end

	def setup_everything
		display "Connecting to #{@real_host}..."
		push_credentials
		launch_rushd
		establish_tunnel
	end

	def push_credentials
		display "Pushing credentials"
		config.ensure_credentials_exist
		ssh_append_to_credentials(config.credentials_file.contents.strip)
	end

	def ssh_append_to_credentials(string)
		# the following horror is exactly why rush is needed
		passwords_file = "~/.rush/passwords"
		string = "'#{string}'"
		ssh "M=`grep #{string} #{passwords_file} | wc -l`; if [ $M = 0 ]; then echo #{string} >> #{passwords_file}; fi"
	end

	def launch_rushd
		display "Launching rushd"
		ssh("if [ `ps aux | grep rushd | grep -v grep | wc -l` -ge 1 ]; then exit; fi; rushd > /dev/null 2>&1 &")
	end

	def establish_tunnel
		display "Establishing ssh tunnel"
		@port = next_available_port

		make_ssh_tunnel

		tunnels = config.tunnels
		tunnels[@real_host] = @port
		config.save_tunnels tunnels

		sleep 0.5
	end

	def tunnel_options
		{
			:local_port => @port,
			:remote_port => Rush::Config::DefaultPort,
			:ssh_host => @real_host,
			:stall_command => "sleep 9000"
		}
	end

	def ensure_still_alive
		setup_everything unless tunnel_alive?
	end

	def tunnel_alive?
		`#{tunnel_count_command}`.to_i > 0
	end

	def tunnel_count_command
		"ps aux | grep '#{ssh_tunnel_command_without_stall}' | grep -v grep | wc -l"
	end

	class SshFailed < Exception; end

	def ssh(command)
		raise SshFailed unless system("ssh #{@real_host} '#{command}'")
	end

	def make_ssh_tunnel
		raise SshFailed unless system(ssh_tunnel_command)
	end

	def ssh_tunnel_command_without_stall
		options = tunnel_options
		"ssh -f -L #{options[:local_port]}:127.0.0.1:#{options[:remote_port]} #{options[:ssh_host]}"
	end

	def ssh_tunnel_command
		ssh_tunnel_command_without_stall + " \"#{tunnel_options[:stall_command]}\""
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
