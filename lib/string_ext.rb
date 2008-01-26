class String
	def head(n)
		slice(0, n)
	end

	def tail(n)
		n = [ n, length ].min
		slice(-n, n)
	end
end
