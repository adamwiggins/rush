class Rush::Access
	attr_accessor :user
	attr_accessor :group
	attr_accessor :user_read, :user_write, :user_execute
	attr_accessor :group_read, :group_write, :group_execute
	attr_accessor :other_read, :other_write, :other_execute

	def initialize(options={})
		parse(options)
	end

	def self.roles
		%w(user group other)
	end

	def self.permissions
		%w(read write execute)
	end

	def parse(options)
		options.each do |key, value|
			if key == :user
				self.user = value
			elsif key == :group
				self.group = value
			else
				perms = extract_list('permission', key, self.class.permissions)
				roles = extract_list('role', value, self.class.roles)
				set_matrix(perms, roles)
			end
		end
	end

	def set_matrix(perms, roles)
		perms.each do |perm|
			roles.each do |role|
				meth = "#{role}_#{perm}=".to_sym
				send(meth, true)
			end
		end
	end

	def extract_list(type, value, choices)
		list = parts_from(value)
		list.each do |value|
			raise(Rush::BadAccessSpecifier, "Unrecognized #{type}: #{value}") unless choices.include? value
		end
	end

	def parts_from(value)
		value.to_s.split('_').reject { |r| r == 'and' }
	end
end
