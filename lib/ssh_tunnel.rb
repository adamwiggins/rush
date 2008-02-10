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

		if config.tunnels[@real_host]
			@port = config.tunnels[@real_host]
		else
			display "Connecting to #{@real_host}..."
			push_credentials
			launch_rushd
			establish_tunnel
		end
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
		ssh("if [ `ps aux | grep rushd | grep -v grep | wc -l` -ge 1 ]; then exit; fi; rushd &")
	end

	def establish_tunnel
		display "Establishing ssh tunnel"
		@port = next_available_port

		make_ssh_tunnel(:local_port => port, :remote_port => Rush::Config::DefaultPort, :ssh_host => @real_host, :stall_command => "sleep 9000")

		tunnels = config.tunnels
		tunnels[@real_host] = port
		config.save_tunnels tunnels

		sleep 0.5
	end

	class SshFailed < Exception; end

	def ssh(command)
		raise SshFailed unless system("ssh #{@real_host} '#{command}'")
	end

	def make_ssh_tunnel(options)
		raise SshFailed unless system("ssh #{build_tunnel_args(options)}")
	end

	def build_tunnel_args(options)
		"-L #{options[:local_port]}:127.0.0.1:#{options[:remote_port]} #{options[:ssh_host]} '#{options[:stall_command]}' &"
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
