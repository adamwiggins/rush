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
			stat[:size]
		end

		def contents
			connection.file_contents(full_path)
		end

		def write(new_contents)
			connection.write_file(full_path, new_contents)
		end

		def lines
			contents.split("\n")
		end

		def search(pattern)
			matching_lines = lines.select { |line| line.match(pattern) }
			matching_lines.size == 0 ? nil : matching_lines
		end

		def replace_contents!(pattern, replace_with)
			write contents.gsub(pattern, replace_with)
		end

		def contents_or_blank
			contents rescue ""
		end

		def line_count
			lines.size
		end

		def lines_or_empty
			lines rescue []
		end

		include Rush::Commands

		def entries
			[ self ]
		end
	end
end
