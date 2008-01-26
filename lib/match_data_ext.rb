class MatchData
	def inspect
		if size == 1
			leadup + green + to_s + normal + leadout
		else
			to_a.join(", ")
		end
	end

	def leadup
		chunk = pre_match.tail(20)
		if m = chunk.match(/\n([^\n]*)/)
			m[1]
		else
			chunk
		end
	end

	def leadout
		chunk = post_match.head(20)
		if m = chunk.match(/([^\n]*)\n/)
			m[1]
		else
			chunk
		end
	end

	def green
		"\e[32;40m"
	end

	def normal
		"\e[0m"
	end
end
