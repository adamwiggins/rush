# Integer extensions for file and dir sizes (returned in bytes).
#
# Example:
#
# box['/assets/'].files_flattened.select { |f| f.size > 10.mb }
class Fixnum
	def kb
		self * 1024
	end

	def mb
		kb * 1024
	end

	def gb
		mb * 1024
	end
end
