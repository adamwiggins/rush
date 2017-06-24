# A rush box is a single unix machine - a server, workstation, or VPS instance.
#
# Specify a box by hostname (default = 'localhost').  If the box is remote, the
# first action performed will attempt to open an ssh tunnel.  Use square
# brackets to access the filesystem, or processes to access the process list.
#
# Example:
#
#   local = Rush::Box.new
#   local['/etc/hosts'].contents
#   local.processes
#
class Rush::Box
  attr_reader :host, :local_path

  # Instantiate a box.  No action is taken to make a connection until you try
  # to perform an action.  If the box is remote, an ssh tunnel will be opened.
  # Specify a username with the host if the remote ssh user is different from
  # the local one (e.g. Rush::Box.new('user@host')).
  def initialize(host='localhost', local_path = nil)
    @host = host
    @local_path = local_path
  end

  def to_s        # :nodoc:
    host
  end

  def inspect     # :nodoc:
    host
  end

  # Access / on the box.
  def filesystem
    if host == 'localhost'
      Rush::Entry.factory('/', self)
    else
      connection.local_path
    end
  end

  # Look up an entry on the filesystem, e.g. box['/path/to/some/file'].
  # Returns a subclass of Rush::Entry - either Rush::Dir if you specifiy
  # trailing slash, or Rush::File otherwise.
  def [](key)
    filesystem[key]
  end

  # Get the list of processes running on the box, not unlike "ps aux" in bash.
  # Returns a Rush::ProcessSet.
  def processes
    Rush::ProcessSet.new(
      connection.processes.map { |ps| Rush::Process.new(ps, self) }
    )
  end

  # Guess if method missing then it's command for folder binded to that box.
  #
  def method_missing(meth, *args, &block)
    filesystem.send(meth, *args, &block)
  end

  # Execute a command in the standard unix shell.  Returns the contents of
  # stdout if successful, or raises Rush::BashFailed with the output of stderr
  # if the shell returned a non-zero value.  Options:
  #
  # :user => unix username to become via sudo
  # :env => hash of environment variables
  # :background => run in the background (returns Rush::Process instead of stdout)
  #
  # Examples:
  #
  #   box.bash '/etc/init.d/mysql restart', :user => 'root'
  #   box.bash 'rake db:migrate', :user => 'www', :env => { :RAILS_ENV => 'production' }
  #   box.bash 'mongrel_rails start', :background => true
  #   box.bash 'rake db:migrate', :user => 'www', :env => { :RAILS_ENV => 'production' }, :reset_environment => true
  #
  def bash(command, options = {})
    cmd_with_env = command_with_environment(command, options[:env])
    options[:reset_environment] ||= false

    if options[:background]
      pid = connection.bash(cmd_with_env, options[:user], true, options[:reset_environment])
      processes.find_by_pid(pid)
    else
      connection.bash(cmd_with_env, options[:user], false, options[:reset_environment])
    end
  end

  def command_with_environment(command, env)   # :nodoc:
    return command unless env
    env.map do |key, value|
      escaped = value.to_s.gsub('"', '\\"').gsub('`', '\\\`')
      "export #{key}=\"#{escaped}\""
    end.push(command).join("\n")
  end

  # Returns true if the box is responding to commands.
  def alive?
    connection.alive?
  end

  # This is called automatically the first time an action is invoked, but you
  # may wish to call it manually ahead of time in order to have the tunnel
  # already set up and running.  You can also use this to pass a timeout option,
  # either :timeout => (seconds) or :timeout => :infinite.
  def establish_connection(options={})
    connection.ensure_tunnel(options)
  end

  def connection         # :nodoc:
    @connection ||= make_connection
  end

  def make_connection    # :nodoc:
    host == 'localhost' ?
      Rush::Connection::Local.new :
      Rush::Connection::Remote.new(host, local_path)
  end

  def ==(other)          # :nodoc:
    host == other.host
  end

  # Print last backtrace
  def wtf
    t = $last_backtrace
    t.lines.count > 5 ? t.less : puts(t)
  end
end
