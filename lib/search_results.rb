module Rush
	class SearchResults
		attr_reader :entries, :lines, :entries_with_lines

		def initialize
			# Duplication of data, but this lets us return everything in the exact
			# order it was received.
			@entries = []
			@entries_with_lines = {}
			@lines = []
		end

		def add(entry, lines)
			# this assumes that entry is unique
			@entries << entry
			@entries_with_lines[entry] = lines
			@lines += lines
		end

		include Rush::Commands

		def each(&block)
			@entries.each(&block)
		end

		include Enumerable
	end
end
