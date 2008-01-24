module Rush
	class Box
		attr_reader :host

		def initialize(host)
			@host = host
		end

		def filesystem
			Rush::Entry.factory('/')
		end

		def [](key)
			filesystem[key]
		end

		class UnknownAction < Exception; end

		def execute(params)
			if host == 'localhost'
				execute_local(params)
			else
				execute_remote(params)
			end
		end

		def execute_local(params)
			if params[:action] == 'write'
				execute_write(params)
			else
				puts params.inspect
				raise UnknownAction
			end
		end

		def execute_remote(params)
			require 'net/http'
			Net::HTTP.start(host, 9000) do |http|
				payload = params.delete(:payload)
				uri = "/?"
				params.each do |key, value|
					uri += "#{key}=#{value}&"
				end
				http.post(uri, payload)
			end
		end

		def execute_write(params)
			self[params[:full_path]].write(params[:payload])
		end
	end
end
