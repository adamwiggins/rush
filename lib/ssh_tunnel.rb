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
			establish_tunnel
		end
	end

	def establish_tunnel
		display "Establishing an ssh tunnel to #{@real_host}..."
		@port = next_available_port

		make_ssh_tunnel(port, '127.0.0.1', Rush::Config::DefaultPort, @real_host, "sleep 9000")

		tunnels = config.tunnels
		tunnels[@real_host] = port
		config.save_tunnels tunnels

		sleep 0.5
	end

	def make_ssh_tunnel(local_port, remote_host, remote_port, ssh_host, stall_command)
		system "ssh -L #{local_port}:#{remote_host}:#{remote_port} #{ssh_host} '#{stall_command}' &"
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
