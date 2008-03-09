require 'rubygems'
require 'mongrel'
require 'base64'

# Mongrel handler that translates the incoming HTTP request into a
# Rush::Connection::Local call.  The results are sent back across the wire to
# be decoded by Rush::Connection::Remote on the other side.
class RushHandler < Mongrel::HttpHandler
	def process(request, response)
		params = {}
		request.params['QUERY_STRING'].split("?").last.split("&").each do |tuple|
			key, value = tuple.split("=")
			params[key.to_sym] = value
		end

		unless authorize(request.params['HTTP_AUTHORIZATION'])
			response.start(401) do |head, out|
			end
		else
			payload = request.body.read

			without_action = params
			without_action.delete(params[:action])

			msg = sprintf "%-20s", params[:action]
			msg += without_action.inspect
			msg += " + #{payload.size} bytes of payload" if payload.size > 0
			log msg

			params[:payload] = payload

			begin
				result = box.connection.receive(params)

				response.start(200) do |head, out|
					out.write result
				end
			rescue Rush::Exception => e
				response.start(400) do |head, out|
					out.write "#{e.class}\n#{e.message}\n"
				end
			end
		end
	rescue Exception => e
		log e.full_display
	end

	def authorize(auth)
		unless m = auth.match(/^Basic (.+)$/)
			log "Request with no authorization data"
			return false
		end

		decoded = Base64.decode64(m[1])
		user, password = decoded.split(':', 2)

		if user.nil? or user.length == 0 or password.nil? or password.length == 0
			log "Malformed user or password"
			return false
		end

		if password == config.passwords[user]
			return true
		else
			log "Access denied to #{user}"
			return false
		end
	end

	def box
		@box ||= Rush::Box.new('localhost')
	end

	def config
		@config ||= Rush::Config.new
	end

	def log(msg)
		File.open('rushd.log', 'a') do |f|
			f.puts "#{Time.now.strftime('%Y-%m-%d %H:%I:%S')} :: #{msg}"
		end
	end
end

# A container class to run the Mongrel server for rushd.
class RushServer
	def run
		host = "127.0.0.1"
		port = Rush::Config::DefaultPort

		rushd = RushHandler.new
		rushd.log "rushd listening on #{host}:#{port}"

		h = Mongrel::HttpServer.new(host, port)
		h.register("/", rushd)
		h.run.join
	end
end

class Exception
	def full_display
		out = []
		out << "Exception #{self.class} => #{self}"
		out << "Backtrace:"
		out << self.filtered_backtrace.collect do |t|
			"   #{t}"
		end
		out << ""
		out.join("\n")
	end

	def filtered_backtrace
		backtrace.reject do |bt|
			bt.match(/^\/usr\//)
		end
	end
end
