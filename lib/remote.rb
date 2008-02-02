require 'yaml'

module Rush
	module Connection
		class Remote
			attr_reader :host

			def initialize(host)
				@host = host
				@real_host = nil
				@real_port = nil
			end

			def write_file(full_path, contents)
				transmit(:action => 'write_file', :full_path => full_path, :payload => contents)
			end

			def file_contents(full_path)
				transmit(:action => 'file_contents', :full_path => full_path)
			end

			def destroy(full_path)
				transmit(:action => 'destroy', :full_path => full_path)
			end

			def create_dir(full_path)
				transmit(:action => 'create_dir', :full_path => full_path)
			end

			def rename(path, name, new_name)
				transmit(:action => 'rename', :path => path, :name => name, :new_name => 'new_name')
			end

			def copy(src, dst)
				transmit(:action => 'copy', :src => src, :dst => dst)
			end

			def read_archive(full_path)
				transmit(:action => 'read_archive', :full_path => full_path)
			end

			def write_archive(archive, dir)
				transmit(:action => 'write_archive', :dir => dir, :payload => archive)
			end

			def index(full_path)
				transmit(:action => 'index', :full_path => full_path).split("\n")
			end

			def stat(full_path)
				YAML.load(transmit(:action => 'stat', :full_path => full_path))
			end

			def size(full_path)
				transmit(:action => 'size', :full_path => full_path)
			end

			class NotAuthorized < Exception; end
			class FailedTransmit < Exception; end

			def transmit(params)
				require 'net/http'

				payload = params.delete(:payload)

				uri = "/?"
				params.each do |key, value|
					uri += "#{key}=#{value}&"
				end

				req = Net::HTTP::Post.new(uri)
				req.basic_auth config.credentials_user, config.credentials_password

				Net::HTTP.start(real_host, real_port) do |http|
					res = http.request(req, payload)
					raise NotAuthorized if res.code == "401"
					raise FailedTransmit if res.code != "200"
					res.body
				end
			end

			def config
				@config ||= Rush::Config.new
			end

			def real_host
				check_tunnel
				@real_host
			end

			def real_port
				check_tunnel
				@real_port
			end

			def check_tunnel
				return if @real_host and @real_port

				if config.tunnels[host]
					@real_host = 'localhost'
					@real_port = config.tunnels[host]
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
				@real_host = 'localhost'
				@real_port = port
				sleep 0.5
			end

			def next_available_port
				(config.tunnels.values.max || Rush::Config::DefaultPort) + 1
			end
		end
	end
end
