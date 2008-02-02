module Rush
	module Commands
		def entries
			raise "must define me in class mixed in to for command use"
		end

		def vi(*args)
			names = entries.map { |f| f.full_path }.join(' ')
			system "vim #{names} #{args.join(' ')}"
		end

		def mate(*args)
			names = entries.map { |f| f.full_path }.join(' ')
			system "mate #{names} #{args.join(' ')}"
		end

		def search(pattern)
			results = Rush::SearchResults.new(pattern)
			entries.each do |entry|
				if !entry.dir? and matches = entry.search(pattern)
					results.add(entry, matches)
				end
			end
			results
		end

		def replace_contents!(pattern, with_text)
			entries.each do |entry|
				entry.replace_contents!(pattern, with_text) unless entry.dir?
			end
		end

		def line_count
			entries.inject(0) do |count, entry|
				count += entry.contents.split("\n").size
			end
		end
	end
end
