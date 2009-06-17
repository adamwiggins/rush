require 'fileutils'
require 'yaml'
require 'timeout'

# Rush::Box uses a connection object to execute all rush commands.  If the box
# is local, Rush::Connection::Local is created.  The local connection is the
# heart of rush's internals.  (Users of the rush shell or library need never
# access the connection object directly, so the docs herein are intended for
# developers wishing to modify rush.)
#
# The local connection has a series of methods which do the actual work of
# modifying files, getting process lists, and so on.  RushServer creates a
# local connection to handle incoming requests; the translation from a raw hash
# of parameters to an executed method is handled by
# Rush::Connection::Local#receive.
class Rush::Connection::Local
	# Write raw bytes to a file.
	def write_file(full_path, contents)
		::File.open(full_path, 'w') do |f|
			f.write contents
		end
		true
	end

	# Append contents to a file
	def append_to_file(full_path, contents)
		::File.open(full_path, 'a') do |f|
			f.write contents
		end
		true
	end

	# Read raw bytes from a file.
	def file_contents(full_path)
		::File.read(full_path)
	rescue Errno::ENOENT
		raise Rush::DoesNotExist, full_path
	end

	# Destroy a file or dir.
	def destroy(full_path)
		raise "No." if full_path == '/'
		FileUtils.rm_rf(full_path)
		true
	end

	# Purge the contents of a dir.
	def purge(full_path)
		raise "No." if full_path == '/'
		Dir.chdir(full_path) do
			all = Dir.glob("*", File::FNM_DOTMATCH).reject { |f| f == '.' or f == '..' }
			FileUtils.rm_rf all
		end
		true
	end

	# Create a dir.
	def create_dir(full_path)
		FileUtils.mkdir_p(full_path)
		true
	end

	# Rename an entry within a dir.
	def rename(path, name, new_name)
		raise(Rush::NameCannotContainSlash, "#{path} rename #{name} to #{new_name}") if new_name.match(/\//)
		old_full_path = "#{path}/#{name}"
		new_full_path = "#{path}/#{new_name}"
		raise(Rush::NameAlreadyExists, "#{path} rename #{name} to #{new_name}") if ::File.exists?(new_full_path)
		FileUtils.mv(old_full_path, new_full_path)
		true
	end

	# Copy ane entry from one path to another.
	def copy(src, dst)
		FileUtils.cp_r(src, dst)
		true
	rescue Errno::ENOENT
		raise Rush::DoesNotExist, File.dirname(dst)
	rescue RuntimeError
		raise Rush::DoesNotExist, src
	end

	# Create an in-memory archive (tgz) of a file or dir, which can be
	# transmitted to another server for a copy or move.  Note that archive
	# operations have the dir name implicit in the archive.
	def read_archive(full_path)
		`cd #{Rush.quote(::File.dirname(full_path))}; tar c #{Rush.quote(::File.basename(full_path))}`
	end

	# Extract an in-memory archive to a dir.
	def write_archive(archive, dir)
		IO.popen("cd #{Rush::quote(dir)}; tar x", "w") do |p|
			p.write archive
		end
	end

	# Get an index of files from the given path with the glob.  Could return
	# nested values if the glob contains a doubleglob.  The return value is an
	# array of full paths, with directories listed first.
	def index(base_path, glob)
		glob = '*' if glob == '' or glob.nil?
		dirs = []
		files = []
		::Dir.chdir(base_path) do
			::Dir.glob(glob).each do |fname|
				if ::File.directory?(fname)
					dirs << fname + '/'
				else
					files << fname
				end
			end
		end
		dirs.sort + files.sort
	rescue Errno::ENOENT
		raise Rush::DoesNotExist, base_path
	end

	# Fetch stats (size, ctime, etc) on an entry.  Size will not be accurate for dirs.
	def stat(full_path)
		s = ::File.stat(full_path)
		{
			:size => s.size,
			:ctime => s.ctime,
			:atime => s.atime,
			:mtime => s.mtime,
			:mode => s.mode
		}
	rescue Errno::ENOENT
		raise Rush::DoesNotExist, full_path
	end

	def set_access(full_path, access)
		access.apply(full_path)
	end

	# Fetch the size of a dir, since a standard file stat does not include the
	# size of the contents.
	def size(full_path)
		`du -sb #{Rush.quote(full_path)}`.match(/(\d+)/)[1].to_i
	end

	# Get the list of processes as an array of hashes.
	def processes
		if ::File.directory? "/proc"
			resolve_unix_uids(linux_processes)
		elsif ::File.directory? "C:/WINDOWS"
			windows_processes
		else
			os_x_processes
		end
	end

	# Process list on Linux using /proc.
	def linux_processes
		list = []
		::Dir["/proc/*/stat"].select { |file| file =~ /\/proc\/\d+\// }.each do |file|
			begin
				list << read_proc_file(file)
			rescue
				# process died between the dir listing and accessing the file
			end
		end
		list
	end

	def resolve_unix_uids(list)
		@uid_map = {} # reset the cache between uid resolutions.
		list.each do |process|
			process[:user] = resolve_unix_uid_to_user(process[:uid])
		end
		list
	end

	# resolve uid to user
	def resolve_unix_uid_to_user(uid)
		require 'etc'

		@uid_map ||= {}
		uid = uid.to_i

		return @uid_map[uid] if !@uid_map[uid].nil?
		
		begin
			record = Etc.getpwuid(uid)
		rescue ArgumentError
			return nil
		end

		@uid_map[uid] = record.name
		@uid_map[uid]
	end

	# Read a single file in /proc and store the parsed values in a hash suitable
	# for use in the Rush::Process#new.
	def read_proc_file(file)
		data = ::File.read(file).split(" ")
		uid = ::File.stat(file).uid
		pid = data[0]
		command = data[1].match(/^\((.*)\)$/)[1]
		cmdline = ::File.read("/proc/#{pid}/cmdline").gsub(/\0/, ' ')
		parent_pid = data[3].to_i
		utime = data[13].to_i
		ktime = data[14].to_i
		vss = data[22].to_i / 1024
		rss = data[23].to_i * 4
		time = utime + ktime

		{
			:pid => pid,
			:uid => uid,
			:command => command,
			:cmdline => cmdline,
			:parent_pid => parent_pid,
			:mem => rss,
			:cpu => time,
		}
	end

	# Process list on OS X or other unixes without a /proc.
	def os_x_processes
		raw = os_x_raw_ps.split("\n").slice(1, 99999)
		raw.map do |line|
			parse_ps(line)
		end
	end

	# ps command used to generate list of processes on non-/proc unixes.
	def os_x_raw_ps
		`COLUMNS=9999 ps ax -o "pid uid ppid rss cpu command"`
	end

	# Parse a single line of the ps command and return the values in a hash
	# suitable for use in the Rush::Process#new.
	def parse_ps(line)
		m = line.split(" ", 6)
		params = {}
		params[:pid] = m[0]
		params[:uid] = m[1]
		params[:parent_pid] = m[2].to_i
		params[:mem] = m[3].to_i
		params[:cpu] = m[4].to_i
		params[:cmdline] = m[5]
		params[:command] = params[:cmdline].split(" ").first
		params
	end

	# Process list on Windows.
	def windows_processes
		require 'win32ole'
		wmi = WIN32OLE.connect("winmgmts://")
		wmi.ExecQuery("select * from win32_process").map do |proc_info|
			parse_oleprocinfo(proc_info)
		end
	end

	# Parse the Windows OLE process info.
	def parse_oleprocinfo(proc_info)
		command = proc_info.Name
		pid = proc_info.ProcessId
		uid = 0
		cmdline = proc_info.CommandLine
		rss = proc_info.MaximumWorkingSetSize
		time = proc_info.KernelModeTime.to_i + proc_info.UserModeTime.to_i

		{
			:pid => pid,
			:uid => uid,
			:command => command,
			:cmdline => cmdline,
			:mem => rss,
			:cpu => time,
		}
	end

	# Returns true if the specified pid is running.
	def process_alive(pid)
		::Process.kill(0, pid)
		true
	rescue Errno::ESRCH
		false
	end

	# Terminate a process, by pid.
	def kill_process(pid, options={})
		# time to wait before terminating the process, in seconds
		wait = options[:wait] || 3

		if wait > 0
			::Process.kill('TERM', pid)

			# keep trying until it's dead (technique borrowed from god)
			begin
				Timeout.timeout(wait) do
					loop do
						return if !process_alive(pid)
						sleep 0.5
						::Process.kill('TERM', pid) rescue nil
					end
				end
			rescue Timeout::Error
			end
		end

		::Process.kill('KILL', pid) rescue nil

	rescue Errno::ESRCH
		# if it's dead, great - do nothing
	end

	def bash(command, user=nil, background=false)
		return bash_background(command, user) if background

		require 'session'

		sh = Session::Bash.new

		if user and user != ""
			out, err = sh.execute "cd /; sudo -H -u #{user} bash", :stdin => command
		else
			out, err = sh.execute command
		end

		retval = sh.status
		sh.close!

		raise(Rush::BashFailed, err) if retval != 0

		out
	end

	def bash_background(command, user)
		pid = fork do
			inpipe, outpipe = IO.pipe

			outpipe.write command
			outpipe.close
			STDIN.reopen(inpipe)

			close_all_descriptors([inpipe.to_i])

			if user and user != ''
				exec "cd /; sudo -H -u #{user} bash"
			else
				exec "bash"
			end
		end

		Process::detach pid

		pid
	end

	def close_all_descriptors(keep_open = [])
		3.upto(256) do |fd|
			next if keep_open.include?(fd)
			IO::new(fd).close rescue nil
		end
	end

	####################################

	# Raised when the action passed in by RushServer is not known.
	class UnknownAction < Exception; end

	# RushServer uses this method to transform a hash (:action plus parameters
	# specific to that action type) into a method call on the connection.  The
	# returned value must be text so that it can be transmitted across the wire
	# as an HTTP response.
	def receive(params)
		case params[:action]
			when 'write_file'     then write_file(params[:full_path], params[:payload])
			when 'append_to_file' then append_to_file(params[:full_path], params[:payload])
			when 'file_contents'  then file_contents(params[:full_path])
			when 'destroy'        then destroy(params[:full_path])
			when 'purge'          then purge(params[:full_path])
			when 'create_dir'     then create_dir(params[:full_path])
			when 'rename'         then rename(params[:path], params[:name], params[:new_name])
			when 'copy'           then copy(params[:src], params[:dst])
			when 'read_archive'   then read_archive(params[:full_path])
			when 'write_archive'  then write_archive(params[:payload], params[:dir])
			when 'index'          then index(params[:base_path], params[:glob]).join("\n") + "\n"
			when 'stat'           then YAML.dump(stat(params[:full_path]))
			when 'set_access'     then set_access(params[:full_path], Rush::Access.from_hash(params))
			when 'size'           then size(params[:full_path])
			when 'processes'      then YAML.dump(processes)
			when 'process_alive'  then process_alive(params[:pid]) ? '1' : '0'
			when 'kill_process'   then kill_process(params[:pid].to_i, YAML.load(params[:payload]))
			when 'bash'           then bash(params[:payload], params[:user], params[:background] == 'true')
		else
			raise UnknownAction
		end
	end

	# No-op for duck typing with remote connection.
	def ensure_tunnel(options={})
	end

	# Local connections are always alive.
	def alive?
		true
	end
end
