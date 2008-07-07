class Rush::ProcessSet
	attr_reader :processes

	def initialize(processes)
		@processes = processes
	end

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

	def kill
		processes.each { |p| p.kill }
	end

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

	def method_missing(meth, *args)
		processes.send(meth, *args)
	end
end
