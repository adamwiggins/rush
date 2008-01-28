module Rush
	class File < Entry
		def dir?
			false
		end

		def create
			write('')
			self
		end

		def size
			stat.size
		end

		def contents
			if box
				box.connection.file_contents(full_path)
			else
				::File.read(full_path)
			end
		end

		def write(new_contents)
			if box
				box.connection.write_file(full_path, new_contents)
			else
				::File.open(full_path, 'w') do |f|
					f.write new_contents
				end
			end
		end

		def replace_contents!(pattern, replace_with)
			write contents.gsub(pattern, replace_with)
		end

		def destroy
			::File.delete(full_path)
		end

		include Rush::Commands

		def entries
			[ self ]
		end
	end
end
