require 'rubygems'
require 'mongrel'

require File.dirname(__FILE__) + '/../lib/rush'

class RushHandler < Mongrel::HttpHandler
	def process(request, response)
		params = {}
		request.params['QUERY_STRING'].split("?").last.split("&").each do |tuple|
			key, value = tuple.split("=")
			params[key.to_sym] = value
		end

		payload = request.body.read

		without_action = params
		without_action.delete(params[:action])
		printf "%-20s", params[:action]
		print without_action.inspect
		print " + #{payload.size} bytes of payload" if payload.size > 0
		puts

		params[:payload] = payload
		result = Rush::Box.new('localhost').connection.receive(params)

		response.start(200) do |head, out|
			out.write result
		end
	end
end

host = "127.0.0.1"
port = RUSH_PORT

puts "rushd listening on #{host}:#{port}"

h = Mongrel::HttpServer.new(host, port)
h.register("/", RushHandler.new)
h.run.join
