require 'yaml'

class Rush::Connection::Remote
	attr_reader :host, :tunnel

	def initialize(host)
		@host = host
		@tunnel = Rush::SshTunnel.new(host)
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

	def index(base_path, glob)
		transmit(:action => 'index', :base_path => base_path, :glob => glob).split("\n")
	end

	def stat(full_path)
		YAML.load(transmit(:action => 'stat', :full_path => full_path))
	end

	def size(full_path)
		transmit(:action => 'size', :full_path => full_path)
	end

	def processes
		YAML.load(transmit(:action => 'processes'))
	end

	class NotAuthorized < Exception; end
	class FailedTransmit < Exception; end

	def transmit(params)
		tunnel.ensure_tunnel

		require 'net/http'

		payload = params.delete(:payload)

		uri = "/?"
		params.each do |key, value|
			uri += "#{key}=#{value}&"
		end

		req = Net::HTTP::Post.new(uri)
		req.basic_auth config.credentials_user, config.credentials_password

		Net::HTTP.start(tunnel.host, tunnel.port) do |http|
			res = http.request(req, payload)
			raise NotAuthorized if res.code == "401"
			raise FailedTransmit if res.code != "200"
			res.body
		end
	end

	def config
		@config ||= Rush::Config.new
	end
end
