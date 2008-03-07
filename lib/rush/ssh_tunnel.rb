# Internal class for managing an ssh tunnel, across which relatively insecure
# HTTP commands can be sent by Rush::Connection::Remote.
class Rush::SshTunnel
	def initialize(real_host)
		@real_host = real_host
	end

	def host
		'localhost'
	end

	def port
		@port
	end

	def ensure_tunnel(options={})
		return if @port and tunnel_alive?

		@port = config.tunnels[@real_host]

		if !@port or !tunnel_alive?
			setup_everything(options)
		end
	end

	def setup_everything(options={})
		display "Connecting to #{@real_host}..."
		push_credentials
		launch_rushd
		establish_tunnel(options)
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
		ssh "M=`grep #{string} #{passwords_file} 2>/dev/null | wc -l`; if [ $M = 0 ]; then mkdir -p .rush; chmod 700 .rush; echo #{string} >> #{passwords_file}; chmod 600 #{passwords_file}; fi"
	end

	def launch_rushd
		display "Launching rushd"
		ssh("if [ `ps aux | grep rushd | grep -v grep | wc -l` -ge 1 ]; then exit; fi; rushd > /dev/null 2>&1 &")
	end

	def establish_tunnel(options={})
		display "Establishing ssh tunnel"
		@port = next_available_port

		make_ssh_tunnel(options)

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
		}
	end

	def tunnel_alive?
		`#{tunnel_count_command}`.to_i > 0
	end

	def tunnel_count_command
		"ps x | grep '#{ssh_tunnel_command_without_stall}' | grep -v grep | wc -l"
	end

	class SshFailed < Exception; end
	class NoPortSelectedYet < Exception; end

	def ssh(command)
		raise SshFailed unless system("ssh #{@real_host} '#{command}'")
	end

	def make_ssh_tunnel(options={})
		raise SshFailed unless system(ssh_tunnel_command(options))
	end

	def ssh_tunnel_command_without_stall
		options = tunnel_options
		raise NoPortSelectedYet unless options[:local_port]
		"ssh -f -L #{options[:local_port]}:127.0.0.1:#{options[:remote_port]} #{options[:ssh_host]}"
	end

	def ssh_stall_command(options={})
		if options[:timeout] == :infinite
			"while [ 1 ]; do sleep 1000; done"
		elsif options[:timeout].to_i > 10
			"sleep #{options[:timeout].to_i}"
		else
			"sleep 9000"
		end
	end

	def ssh_tunnel_command(options={})
		ssh_tunnel_command_without_stall + ' "' + ssh_stall_command(options) + '"'
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
