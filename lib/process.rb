module Rush
	class Process
		attr_reader :pid, :uid, :command, :cmdline, :mem, :cpu

		def initialize(params)
			@pid = params[:pid].to_i
			@uid = params[:uid].to_i
			@command = params[:command]
			@cmdline = params[:cmdline]
			@mem = params[:rss]
			@cpu = params[:time]
		end

		def to_s
			inspect
		end

		def inspect
			"Process #{@pid}: #{@cmdline}"
		end

		def alive?
			::File.exists? "/proc/#{pid}"
		end

		def kill
			::Process.kill('TERM', pid)
		end

		def self.read_stat_file(file)
			data = ::File.read(file).split(" ")
			uid = ::File.stat(file).uid
			pid = data[0]
			command = data[1].match(/^\((.*)\)$/)[1]
			cmdline = ::File.read("/proc/#{pid}/cmdline")
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
				:mem => rss,
				:cpu => time,
			}
		end

		def self.all
			list = []
			::Dir["/proc/*/stat"].select { |file| file =~ /\/proc\/\d+\// }.each do |file|
				begin
					list << new(read_stat_file(file))
				rescue Exception
					# just ignore exception - process died between the dir listing and accessing the file
				end
			end
			list
		end
	end
end  
