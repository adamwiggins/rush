module Rush
	module Commands
		def entries
			raise "must define me in class mixed in to for command use"
		end

		def vi(*args)
			names = entries.map { |f| f.full_path }.join(' ')
			system "vim #{names} #{args.join(' ')}"
		end

		def search(pattern)
			entries.select do |entry|
				!entry.directory? and entry.contents.match(pattern)
			end
		end

		def replace!(pattern, with_text)
			entries.each do |entry|
				entry.replace!(pattern, with_text) unless entry.directory?
			end
		end
	end
end
