module Rush
	module Connection
		class Local
			def write_file(full_path, contents)
				::File.open(full_path, 'w') do |f|
					f.write contents
				end
				true
			end

			def file_contents(full_path)
				::File.read(full_path)
			end

			class UnknownAction < Exception; end

			def receive(params)
				if params[:action] == 'write_file'
					write_file(params[:full_path], params[:payload])
				elsif params[:action] == 'file_contents'
					file_contents(params[:full_path])
				else
					raise UnknownAction
				end
			end
		end
	end
end
