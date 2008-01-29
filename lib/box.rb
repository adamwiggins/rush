module Rush
	class Box
		attr_reader :host

		def initialize(host='localhost')
			@host = host
		end

		def to_s
			host
		end

		def filesystem
			Rush::Entry.factory('/', self)
		end

		def [](key)
			filesystem[key]
		end

		def connection
			@connection ||= make_connection
		end

		def make_connection
			host == 'localhost' ? Rush::Connection::Local.new : Rush::Connection::Remote.new(host)
		end
	end
end
