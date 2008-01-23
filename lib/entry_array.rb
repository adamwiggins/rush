module Rush
	class EntryArray < Array
		def grep(pattern)
			select do |file|
				!file.directory? and file.contents.match(pattern)
			end
		end
	end
end
