class Array
	include Rush::Commands

	def entries
		self
	end

	include Rush::HeadTail
end
