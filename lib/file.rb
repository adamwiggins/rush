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
			connection.file_contents(full_path)
		end

		def write(new_contents)
			connection.write_file(full_path, new_contents)
		end

		def replace_contents!(pattern, replace_with)
			write contents.gsub(pattern, replace_with)
		end

		include Rush::Commands

		def entries
			[ self ]
		end
	end
end
