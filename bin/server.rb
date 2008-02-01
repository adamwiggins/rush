require 'rubygems'
require 'mongrel'
require 'base64'

require File.dirname(__FILE__) + '/../lib/rush'

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

	def authorize(auth)
		return false unless m = auth.match(/^Basic (.+)$/)
		sent_token = m[1].strip
		user = 'user'
		password = 'password'
		correct_token = Base64.encode64("#{user}:#{password}").strip
		return sent_token == correct_token
	end
end

host = "127.0.0.1"
port = RUSH_PORT

puts "rushd listening on #{host}:#{port}"

h = Mongrel::HttpServer.new(host, port)
h.register("/", RushHandler.new)
h.run.join
