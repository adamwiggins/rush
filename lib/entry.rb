module Rush
	class Entry
		attr_reader :name

		def initialize(full_path)
			@path = ::File.dirname(full_path)
			@name = ::File.basename(full_path)
		end

		def parent
			@parent ||= Rush::Dir.new(@path)
		end

		def full_path
			"#{@path}/#{@name}"
		end

		def created_at
			stat.ctime
		end

		def last_modified
			stat.mtime
		end

		def last_accessed
			stat.atime
		end

		class NameAlreadyExists < Exception; end

		def rename(new_name)
			raise NameAlreadyExists if ::File.exists?("#{@path}/#{new_name}")
			system "cd #{@path}; mv #{name} #{new_name}"
			@name = new_name
		end

		def move_to(dir)
			raise NameAlreadyExists if ::File.exists?("#{dir.full_path}/#{name}")
			system "mv #{full_path} #{dir.full_path}"
			@path = dir.full_path
			@parent = dir
		end

	private

		def stat
			::File.stat(full_path)
		end
	end
end
