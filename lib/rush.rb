require 'etc' # get info from /etc

# The top-level Rush module has some convenience methods for accessing the
# local box.
module Rush
  # Access the root filesystem of the local box.
  #
  # @param key [String] relative path.
  # @example
  #   Rush['/etc/hosts'].contents
  #
  def self.[](key)
    box[key]
  end

  # Create a dir object from the path of a provided file.
  #
  # @param filename [String] path that should be created.
  # @example
  #   Rush.dir(__FILE__).files
  #
  def self.dir(filename)
    box[::File.expand_path(::File.dirname(filename)) + '/']
  end

  # Create a dir object based on the shell's current working directory at the
  # time the program was run.
  #
  # @example
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

  # Pull the process list for the local machine.
  #
  # @example
  #   Rush.processes.filter(:cmdline => /ruby/)
  #
  def self.processes
    box.processes
  end

  # Get the process object for this program's PID.
  #
  # @example
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

require_relative 'rush/exceptions'
require_relative 'rush/config'
require_relative 'rush/commands'
require_relative 'rush/access'
require_relative 'rush/path'
require_relative 'rush/entry'
require_relative 'rush/file'
require_relative 'rush/dir'
require_relative 'rush/search_results'
require_relative 'rush/head_tail'
require_relative 'rush/find_by'
require_relative 'rush/string_ext'
require_relative 'rush/fixnum_ext'
require_relative 'rush/array_ext'
require_relative 'rush/process'
require_relative 'rush/process_set'
require_relative 'rush/local'
require_relative 'rush/box'
require_relative 'rush/embeddable_shell'
