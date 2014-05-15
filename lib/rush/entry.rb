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
    elsif File.directory?(full_path)
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

  def quoted_path
    Rush.quote(full_path)
  end

  # Return true if the entry currently exists on the filesystem of the box.
  def exists?
    stat
    true
  rescue Rush::DoesNotExist
    false
  end

  # Timestamp of most recent change to the entry (permissions, contents, etc).
  def changed_at
    stat[:ctime]
  end

  # Timestamp of last modification of the contents.
  def last_modified
    stat[:mtime]
  end

  # Timestamp that entry was last accessed (read from or written to).
  def last_accessed
    stat[:atime]
  end

  # Rename an entry to another name within the same dir.  The object's name
  # will be updated to match the change on the filesystem.
  def rename(new_name)
    connection.rename(@path, @name, new_name)
    @name = new_name
    self
  end
  alias_method :mv, :rename

  # Rename an entry to another name within the same dir.  The existing object
  # will not be affected, but a new object representing the newly-created
  # entry will be returned.
  def duplicate(new_name)
    raise Rush::NameCannotContainSlash if new_name.match(/\//)
    new_full_path = "#{@path}/#{new_name}"
    connection.copy(full_path, new_full_path)
    self.class.new(new_full_path, box)
  end

  # Copy the entry to another dir.  Returns an object representing the new
  # copy.
  def copy_to(dir)
    raise Rush::NotADir unless dir.class == Rush::Dir

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

  # Set the access permissions for the entry.
  #
  # Permissions are set by role and permissions combinations which can be specified individually
  # or grouped together.  :user_can => :read, :user_can => :write is the same
  # as :user_can => :read_write.
  #
  # You can also insert 'and' if you find it reads better, like :user_and_group_can => :read_and_write.
  #
  # Any permission excluded is set to deny access.  The access call does not set partial
  # permissions which combine with the existing state of the entry, like "chmod o+r" would.
  #
  # Examples:
  #
  #   file.access = { :user_can => :read_write, :group_other_can => :read }
  #   dir.access = { :user => 'adam', :group => 'users', :read_write_execute => :user_group }
  #
  def access=(options)
    connection.set_access(full_path, Rush::Access.parse(options))
  end

  # Returns a hash with up to nine values, combining user/group/other with read/write/execute.
  # The key is omitted if the value is false.
  #
  # Examples:
  #
  #   entry.access                   # -> { :user_can_read => true, :user_can_write => true, :group_can_read => true }
  #   entry.access[:other_can_read]  # -> true or nil
  #
  def access
    Rush::Access.new.from_octal(stat[:mode]).display_hash
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
