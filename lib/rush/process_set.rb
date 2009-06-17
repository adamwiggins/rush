# A container for processes that behaves like an array, and adds process-specific operations
# on the entire set, like kill.
#
# Example:
#
#   processes.filter(:cmdline => /mongrel_rails/).kill
#
class Rush::ProcessSet
	attr_reader :processes

	def initialize(processes)
		@processes = processes
	end

	# Filter by any field that the process responds to.  Specify an exact value,
	# or a regular expression.  All conditions are put together as a boolean
	# AND, so these two statements are equivalent:
	#
	#   processes.filter(:uid => 501).filter(:cmdline => /ruby/)
	#   processes.filter(:uid => 501, :cmdline => /ruby/)
	#
	def filter(conditions)
		Rush::ProcessSet.new(
			processes.select do |p|
				conditions.all? do |key, value|
					value.class == Regexp ?
						value.match(p.send(key)) :
						p.send(key) == value
				end
			end
		)
	end

	# Kill all processes in the set.
	def kill(options={})
		processes.each { |p| p.kill(options) }
	end

	# Check status of all processes in the set, returns an array of booleans.
	def alive?
		processes.map { |p| p.alive? }
	end

	include Enumerable

	def each
		processes.each { |p| yield p }
	end

	def ==(other)
		if other.class == self.class
			other.processes == processes
		else
			to_a == other
		end
	end

	# All other messages (like size or first) are passed through to the array.
	def method_missing(meth, *args)
		processes.send(meth, *args)
	end
end
