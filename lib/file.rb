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

		def gsub_contents!(pattern, replace_with)
			new_contents = contents.gsub(pattern, replace_with)
			::File.open(full_path, 'w') do |f|
				f.write new_contents
			end
		end

		def destroy
			::File.delete(full_path)
		end
	end
end
