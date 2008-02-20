# Mixin for array and string for methods I wish they had.
module Rush::HeadTail
	def head(n)
		slice(0, n)
	end

	def tail(n)
		n = [ n, length ].min
		slice(-n, n)
	end
end
