class Array
	include Rush::Commands

	def entries
		self
	end
end

class Hash
	include Rush::Commands

	def entries
		keys
	end
end
