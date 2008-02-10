class Rush::SshTunnel
	def initialize(real_host)
		@real_host = host
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
		puts "Establishing an ssh tunnel to #{host}..."
		port = next_available_port
		system "ssh -L #{port}:127.0.0.1:7770 #{host} 'sleep 9000' &"
		tunnels = config.tunnels
		tunnels[host] = port
		config.save_tunnels tunnels
		@port = port
		sleep 0.5
	end

	def next_available_port
		(config.tunnels.values.max || Rush::Config::DefaultPort) + 1
	end

	def config
		@config ||= Rush::Config.new
	end
end
