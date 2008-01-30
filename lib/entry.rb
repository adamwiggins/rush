module Rush
	class Entry
		attr_reader :box, :name, :path

		def initialize(full_path, box=nil)
			full_path = ::File.expand_path(full_path, '/')
			@path = ::File.dirname(full_path)
			@name = ::File.basename(full_path)
			@box = box
		end

		def self.factory(full_path, box=nil)
			if full_path.tail(1) == '/'
				Rush::Dir.new(full_path, box)
			else
				Rush::File.new(full_path, box)
			end
		end

		def to_s
			if box.host == 'localhost'
				"#{full_path}"
			else
				inspect
			end
		end

		def inspect
			"#{box}:#{full_path}"
		end

		def connection
			box ? box.connection : Rush::Connection::Local.new
		end

		def parent
			@parent ||= Rush::Dir.new(@path)
		end

		def full_path
			"#{@path}/#{@name}"
		end

		def created_at
			stat[:ctime]
		end

		def last_modified
			stat[:mtime]
		end

		def last_accessed
			stat[:atime]
		end

		class NameAlreadyExists < Exception; end
		class NameCannotContainSlash < Exception; end
		class NotADir < Exception; end

		def rename(new_name)
			connection.rename(@path, @name, new_name)
			@name = new_name
		end

		def duplicate(new_name)
			raise NameCannotContainSlash if new_name.match(/\//)
			new_full_path = "#{@path}/#{new_name}"
			connection.copy(full_path, new_full_path)
			self.class.new(new_full_path, box)
		end

		def copy_to(dir)
			raise NotADir unless dir.class == Rush::Dir

			if box == dir.box
				connection.copy(full_path, dir.full_path)
			else
				archive = connection.read_archive(full_path)
				dir.box.connection.write_archive(archive, dir.full_path)
			end

			new_full_path = "#{dir.full_path}#{name}"
			self.class.new(new_full_path, dir.box)
		end

		def move_to(dir)
			moved = copy_to(dir)
			destroy
			mimic(moved)
		end

		def mimic(from)
			@box = from.box
			@path = from.path
			@name = from.name
		end

		def hidden?
			name.slice(0, 1) == '.'
		end

		def destroy
			connection.destroy(full_path)
		end

		def ==(other)
			full_path == other.full_path and box == other.box
		end

	private

		def stat
			connection.stat(full_path)
		end
	end
end
