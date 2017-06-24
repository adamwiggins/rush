# A dir is a subclass of Rush::Entry that contains other entries.  Also known
# as a directory or a folder.
#
# Dirs can be operated on with Rush::Commands the same as an array of files.
# They also offer a square bracket accessor which can use globbing to get a
# list of files.
#
# Example:
#
#   dir = box['/home/adam/']
#   dir['**/*.rb'].line_count
#
# In the interactive shell, dir.ls is a useful command.
class Rush::Dir < Rush::Entry
	def dir?
		true
	end

	def full_path
		"#{super}/"
	end
  alias_method :dirname, :full_path

	# Entries contained within this dir - not recursive.
	def contents
		find_by_glob('*') + find_by_glob('.[!.]*')
	end

	# Files contained in this dir only.
	def files
		contents.reject(&:dir?)
	end

	# Other dirs contained in this dir only.
	def dirs
		contents.select(&:dir?)
	end

	# Access subentries with square brackets, e.g. dir['subdir/file']
	def [](key)
		key = key.to_s
    case
    when key == '**'     then files_flattened
    when key.match(/\*/) then find_by_glob(key)
		else find_by_name(key)
		end
	end
	# Slashes work as well, e.g. dir/'subdir/file'
	alias_method :/, :[]

  def locate(path)
    located = bash("locate -i #{path}").split("\n").
      map { |x| x.dir? ? Rush::Dir.new(x) : Rush::File.new(x) }
    located.size == 1 ? located.first : located
  end

  def locate_dir(path)
    located = bash("locate -r #{path}$").split("\n").
      map { |x| Dir.new x }
    located.size == 1 ? located.first : located
  end

	def find_by_name(name)    # :nodoc:
		Rush::Entry.factory("#{full_path}/#{name}", box)
	end

	def find_by_glob(glob)    # :nodoc:
		connection.index(full_path, glob).map do |fname|
			Rush::Entry.factory("#{full_path}/#{fname}", box)
		end
	end

	# A list of all the recursively contained entries in flat form.
	def entries_tree
		find_by_glob('**/*')
	end

	# Recursively contained files.
	def files_flattened
		entries_tree.reject(&:dir?)
	end

	# Recursively contained dirs.
	def dirs_flattened
		entries_tree.select(&:dir?)
	end

	# Given a list of flat filenames, product a list of entries under this dir.
	# Mostly for internal use.
	def make_entries(filenames)
		Array(filenames).
      map { |fname| Rush::Entry.factory("#{full_path}/#{fname}") }
	end

	# Create a blank file within this dir.
	def create_file(name)
		file = self[name].create
		file.write('')
		file
	end

	# Create an empty subdir within this dir.
	def create_dir(name)
		name += '/' unless name[-1] == '/'
		self[name].create
	end

	# Create an instantiated but not yet filesystem-created dir.
	def create
		connection.create_dir(full_path)
		self
	end

	# Get the total disk usage of the dir and all its contents.
	def size
		connection.size(full_path)
	end

	# Contained dirs that are not hidden.
	def nonhidden_dirs
		dirs.reject(&:hidden?)
	end

	# Contained files that are not hidden.
	def nonhidden_files
		files.reject(&:hidden?)
	end

	# Run a bash command starting in this directory.  Options are the same as Rush::Box#bash.
	def bash(command, options={})
		box.bash "cd #{quoted_path} && #{command}", options
	end

	# Destroy all of the contents of the directory, leaving it fresh and clean.
	def purge
		connection.purge full_path
	end

	# Text output of dir listing, equivalent to the regular unix shell's ls command.
  def ls(*args)
    output_of 'ls', *args
  end

	# Run rake within this dir.
	def rake(*args)
		bash "rake #{args.join(' ')}"
	end

	# Run git within this dir.
	def git(*args)
		bash "git #{args.join(' ')}"
	end

	include Rush::Commands

	def entries
		contents
	end
end
