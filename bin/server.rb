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

		params[:payload] = request.body.read

		puts params.inspect

		box = Rush::Box.new('localhost').execute(params)

		response.start(200) do |head, out|
			out.write ""
		end
	end
end

h = Mongrel::HttpServer.new("0.0.0.0", "9000")
h.register("/", RushHandler.new)
h.run.join
