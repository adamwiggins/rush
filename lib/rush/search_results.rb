class Rush::SearchResults
	attr_reader :entries, :lines, :entries_with_lines, :pattern

	def initialize(pattern)
		# Duplication of data, but this lets us return everything in the exact
		# order it was received.
		@pattern = pattern
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

	def colorize(line)
		lowlight + line.gsub(/(#{pattern.source})/, "#{hilight}\\1#{lowlight}") + normal
	end

	def hilight
		"\e[34;1m"
	end

	def lowlight
		"\e[37;2m"
	end

	def normal
		"\e[0m"
	end
end
