# Generic find_by (returns first match) and find_all_by (returns all matches)
# against arrays.
#
# Examples:
#
#   processes.find_by_pid(::Process.pid)
#   processes.find_all_by_cmdline(/mongrel_rails/)
#
module Rush::FindBy
	def method_missing(meth, *args)
		if m = meth.to_s.match(/^find_by_([a-z_]+)$/)
			find_by(m[1], args.first)
		elsif m = meth.to_s.match(/^find_all_by_([a-z_]+)$/)
			find_all_by(m[1], args.first)
		else
			super
		end
	end

	def find_by(field, arg)
		detect do |item|
			item.respond_to?(field) and compare_or_match(item.send(field), arg)
		end
	end

	def find_all_by(field, arg)
		select do |item|
			item.respond_to?(field) and compare_or_match(item.send(field), arg)
		end
	end

	def compare_or_match(value, against)
		if against.class == Regexp
			value.match(against) ? true : false
		else
			value == against
		end
	end
end
