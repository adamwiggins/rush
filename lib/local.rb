require 'fileutils'

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

			def destroy(full_path)
				raise "No." if full_path == '/'
				FileUtils.rm_rf(full_path)
			end

			def create_dir(full_path)
				FileUtils.mkdir_p(full_path)
			end

			class UnknownAction < Exception; end

			def receive(params)
				case params[:action]
					when 'write_file'     then write_file(params[:full_path], params[:payload])
					when 'file_contents'  then file_contents(params[:full_path])
					when 'destroy'        then destroy(params[:full_path])
					when 'create_dir'     then create_dir(params[:full_path])
				else
					raise UnknownAction
				end
			end
		end
	end
end
