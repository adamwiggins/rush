module Rush
	class File < Entry
		def directory?
			false
		end

		def size
			stat.size
		end

		def contents
			::File.read(full_path)
		end

		def write(new_contents)
			::File.open(full_path, 'w') do |f|
				f.write new_contents
			end
		end

		def gsub_contents!(pattern, replace_with)
			write contents.gsub(pattern, replace_with)
		end

		def destroy
			::File.delete(full_path)
		end
	end
end
