require 'rubygems'

# The top-level Rush module has some convenience methods for accessing the
# local box.
module Rush
	# Access the root filesystem of the local box.  Example:
	#
	#   Rush['/etc/hosts'].contents
	#
	def self.[](key)
		box[key]
	end

	# Create a dir object from the path of a provided file.  Example:
	#
	#   Rush.dir(__FILE__).files
	#
	def self.dir(filename)
		box[::File.expand_path(::File.dirname(filename)) + '/']
	end

	# Create a dir object based on the shell's current working directory at the
	# time the program was run.  Example:
	#
	#   Rush.launch_dir.files
	#
	def self.launch_dir
		box[::Dir.pwd + '/']
	end

	# Run a bash command in the root of the local machine.  Equivalent to
	# Rush::Box.new.bash.
	def self.bash(command, options={})
		box.bash(command, options)
	end

	# Pull the process list for the local machine.  Example:
   #
   #   Rush.processes.filter(:cmdline => /ruby/)
	#
	def self.processes
		box.processes
	end

	# Get the process object for this program's PID.  Example:
   #
   #   puts "I'm using #{Rush.my_process.mem} blocks of memory"
	#
	def self.my_process
		box.processes.filter(:pid => ::Process.pid).first
	end

	# Create a box object for localhost.
	def self.box
		@@box = Rush::Box.new
	end

	# Quote a path for use in backticks, say.
	def self.quote(path)
		path.gsub(/(?=[^a-zA-Z0-9_.\/\-\x7F-\xFF\n])/n, '\\').gsub(/\n/, "'\n'").sub(/^$/, "''")
	end
end

module Rush::Connection; end

$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rush/exceptions'
require 'rush/config'
require 'rush/commands'
require 'rush/access'
require 'rush/entry'
require 'rush/file'
require 'rush/dir'
require 'rush/search_results'
require 'rush/head_tail'
require 'rush/find_by'
require 'rush/string_ext'
require 'rush/fixnum_ext'
require 'rush/array_ext'
require 'rush/process'
require 'rush/process_set'
require 'rush/local'
require 'rush/remote'
require 'rush/ssh_tunnel'
require 'rush/box'
require 'rush/embeddable_shell'
