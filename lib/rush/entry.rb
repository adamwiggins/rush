# Rush::Entry is the base class for Rush::File and Rush::Dir.  One or more of
# these is instantiated whenever you use square brackets to access the
# filesystem on a box, as well as any other operation that returns an entry or
# list of entries.
class Rush::Entry
	attr_reader :box, :name, :path

	# Initialize with full path to the file or dir, and the box it resides on.
	def initialize(full_path, box=nil)
		full_path = ::File.expand_path(full_path, '/')
		@path = ::File.dirname(full_path)
		@name = ::File.basename(full_path)
		@box = box || Rush::Box.new('localhost')
	end

	# The factory checks to see if the full path has a trailing slash for
	# creating a Rush::Dir rather than the default Rush::File.
	def self.factory(full_path, box=nil)
		if full_path.tail(1) == '/'
			Rush::Dir.new(full_path, box)
		else
			Rush::File.new(full_path, box)
		end
	end

	def to_s      # :nodoc:
		if box.host == 'localhost'
			"#{full_path}"
		else
			inspect
		end
	end

	def inspect   # :nodoc:
		"#{box}:#{full_path}"
	end

	def connection
		box ? box.connection : Rush::Connection::Local.new
	end

	# The parent dir.  For example, box['/etc/hosts'].parent == box['etc/']
	def parent
		@parent ||= Rush::Dir.new(@path)
	end

	def full_path
		"#{@path}/#{@name}"
	end

	# Return true if the entry currently exists on the filesystem of the box.
	def exists?
		stat
		true
	rescue Rush::DoesNotExist
		false
	end

	# Timestamp of entry creation.
	def created_at
		stat[:ctime]
	end

	# Timestamp that entry was last modified on.
	def last_modified
		stat[:mtime]
	end

	# Timestamp that entry was last accessed on.
	def last_accessed
		stat[:atime]
	end

	# Attempts to rename, copy, or otherwise place an entry into a dir that already contains an entry by that name will fail with this exception.
	class NameAlreadyExists < Exception; end

	# Do not use rename or duplicate with a slash; use copy_to or move_to instead.
	class NameCannotContainSlash < Exception; end

	# Rename an entry to another name within the same dir.  The object's name
	# will be updated to match the change on the filesystem.
	def rename(new_name)
		connection.rename(@path, @name, new_name)
		@name = new_name
	end

	# Rename an entry to another name within the same dir.  The existing object
	# will not be affected, but a new object representing the newly-created
	# entry will be returned.
	def duplicate(new_name)
		raise NameCannotContainSlash if new_name.match(/\//)
		new_full_path = "#{@path}/#{new_name}"
		connection.copy(full_path, new_full_path)
		self.class.new(new_full_path, box)
	end

	# Copy the entry to another dir.  Returns an object representing the new
	# copy.
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

	# Move the entry to another dir.  The object will be updated to show its new
	# location.
	def move_to(dir)
		moved = copy_to(dir)
		destroy
		mimic(moved)
	end

	def mimic(from)      # :nodoc:
		@box = from.box
		@path = from.path
		@name = from.name
	end

	# Unix convention considers entries starting with a . to be hidden.
	def hidden?
		name.slice(0, 1) == '.'
	end

	# Set the permissions and ownership for the entry.
	# Ownership is set by :user and :group.
	#
	# Permissions are set by role and permissions combinations which can be specified individually
	# or grouped together - :read => :user, :write => :user is the same as :read_write => :user.
	#
	# You can also insert 'and' if you find it reads better, like :read_and_write => :user_and_group.
	#
	# Any permission excluded is set to deny access.  The access call does not set partial
	# permissions which combine with the existing state of the entry, like "chmod o+r" would.
	#
	# Examples:
	#
	#   file.access = { :user => 'adam', :group => 'users', :read_and_write => :user, :read => :group_and_other }
	#   dir.access = { :user => 'adam', :group => 'users', :read_write_execute => :user_group }
	#
	def access=(options)
		connection.set_access(full_path, Rush::Access.parse(options))
	end

	# Destroy the entry.  If it is a dir, everything inside it will also be destroyed.
	def destroy
		connection.destroy(full_path)
	end

	def ==(other)       # :nodoc:
		full_path == other.full_path and box == other.box
	end

private

	def stat
		connection.stat(full_path)
	end
end
