class Rush::Access
	attr_accessor :user
	attr_accessor :group
	attr_accessor :user_read, :user_write, :user_execute
	attr_accessor :group_read, :group_write, :group_execute
	attr_accessor :other_read, :other_write, :other_execute

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
		self
	end

	def self.parse(options)
		new.parse(options)
	end

	def apply(full_path)
		FileUtils.chmod(octal_permissions, full_path)
	rescue Errno::ENOENT
		raise Rush::DoesNotExist, full_path
	end

	def to_hash
		hash = { :user => user, :group => group }
		self.class.roles.each do |role|
			self.class.permissions.each do |perm|
				key = "#{role}_#{perm}".to_sym
				hash[key] = send(key) ? 1 : 0
			end
		end
		hash
	end

	def from_hash(hash)
		self.user = hash[:user]
		self.group = hash[:group]
		self.class.roles.each do |role|
			self.class.permissions.each do |perm|
				key = "#{role}_#{perm}"
				send("#{key}=".to_sym, hash[key.to_sym].to_i == 1 ? true : false)
			end
		end
		self
	end

	def self.from_hash(hash)
		new.from_hash(hash)
	end

	def octal_permissions
		perms = [ 0, 0, 0 ]
		perms[0] += 4 if user_read
		perms[0] += 2 if user_write
		perms[0] += 1 if user_execute
		
		perms[1] += 4 if group_read
		perms[1] += 2 if group_write
		perms[1] += 1 if group_execute

		perms[2] += 4 if other_read
		perms[2] += 2 if other_write
		perms[2] += 1 if other_execute

		eval("0" + perms.join)
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
