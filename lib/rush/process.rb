# An array of these objects is returned by Rush::Box#processes.
class Rush::Process
	attr_reader :box, :pid, :uid, :parent_pid, :command, :cmdline, :mem, :cpu, :user

	# params is a hash returned by the system-specific method of looking up the
	# process list.
	def initialize(params, box)
		@box = box

		@pid = params[:pid].to_i
		@uid = params[:uid].to_i
		@user = params[:user]
		@command = params[:command]
		@cmdline = params[:cmdline]
		@mem = params[:mem]
		@cpu = params[:cpu]
		@parent_pid = params[:parent_pid]
	end

	def to_s      # :nodoc:
		inspect
	end

	def inspect   # :nodoc:
		if box.to_s != 'localhost'
			"#{box} #{@pid}: #{@cmdline}"
		else
			"#{@pid}: #{@cmdline}"
		end
	end

	# Returns the Rush::Process parent of this process.
	def parent
		box.processes.select { |p| p.pid == parent_pid }.first
	end

	# Returns an array of child processes owned by this process.
	def children
		box.processes.select { |p| p.parent_pid == pid }
	end

	# Returns true if the process is currently running.
	def alive?
		box.connection.process_alive(pid)
	end

	# Terminate the process.
	def kill(options={})
		box.connection.kill_process(pid, options)
	end

	def ==(other)       # :nodoc:
		pid == other.pid and box == other.box
	end

	def self.all
		Rush::Box.new('localhost').processes
	end
end  
