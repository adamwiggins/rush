require 'fileutils'
require 'yaml'

class Rush::Connection::Local
	def write_file(full_path, contents)
		::File.open(full_path, 'w') do |f|
			f.write contents
		end
		true
	end

	def file_contents(full_path)
		::File.read(full_path)
	end

	def destroy(full_path)
		raise "No." if full_path == '/'
		FileUtils.rm_rf(full_path)
		true
	end

	def create_dir(full_path)
		FileUtils.mkdir_p(full_path)
		true
	end

	class NameAlreadyExists < Exception; end
	class NameCannotContainSlash < Exception; end
	class NotADir < Exception; end

	def rename(path, name, new_name)
		raise NameCannotContainSlash if new_name.match(/\//)
		old_full_path = "#{path}/#{name}"
		new_full_path = "#{path}/#{new_name}"
		raise NameAlreadyExists if ::File.exists?(new_full_path)
		FileUtils.mv(old_full_path, new_full_path)
		true
	end

	def copy(src, dst)
		FileUtils.cp_r(src, dst)
		true
	end

	# archive ops have the dir name implicit in the archive
	def read_archive(full_path)
		`cd #{::File.dirname(full_path)}; tar c #{::File.basename(full_path)}`
	end

	def write_archive(archive, dir)
		IO.popen("cd #{dir}; tar x", "w") do |p|
			p.write archive
		end
	end

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
		dirs + files
	end

	def stat(full_path)
		s = ::File.stat(full_path)
		{
			:size => s.size,
			:ctime => s.ctime,
			:atime => s.atime,
			:mtime => s.mtime,
		}
	end

	def size(full_path)
		`du -sb #{full_path}`.match(/(\d+)/)[1].to_i
	end

	def processes
		if ::File.directory? "/proc"
			linux_processes
		else
			os_x_processes
		end
	end

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

	def read_proc_file(file)
		data = ::File.read(file).split(" ")
		uid = ::File.stat(file).uid
		pid = data[0]
		command = data[1].match(/^\((.*)\)$/)[1]
		cmdline = ::File.read("/proc/#{pid}/cmdline").gsub(/\0/, ' ')
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

	def os_x_raw_ps
		`COLUMNS=9999 ps ax -o "pid uid rss cpu command"`
	end

	def os_x_processes
		raw = os_x_raw_ps.split("\n").slice(1, 99999)
		raw.map do |line|
			parse_ps(line)
		end
	end

	def parse_ps(line)
		m = line.split(" ", 5)
		params = {}
		params[:pid] = m[0]
		params[:uid] = m[1]
		params[:mem] = m[2]
		params[:cpu] = m[3]
		params[:cmdline] = m[4]
		params[:command] = params[:cmdline].split(" ").first
		params
	end

	def process_alive(pid)
		`ps -p #{pid} | wc -l`.to_i >= 2
	end

	def kill_process(pid)
		::Process.kill('TERM', pid.to_i)
	end

	####################################

	class UnknownAction < Exception; end

	def receive(params)
		case params[:action]
			when 'write_file'     then write_file(params[:full_path], params[:payload])
			when 'file_contents'  then file_contents(params[:full_path])
			when 'destroy'        then destroy(params[:full_path])
			when 'create_dir'     then create_dir(params[:full_path])
			when 'rename'         then rename(params[:path], params[:name], params[:new_name])
			when 'copy'           then copy(params[:src], params[:dst])
			when 'read_archive'   then read_archive(params[:full_path])
			when 'write_archive'  then write_archive(params[:payload], params[:dir])
			when 'index'          then index(params[:base_path], params[:glob]).join("\n") + "\n"
			when 'stat'           then YAML.dump(stat(params[:full_path]))
			when 'size'           then size(params[:full_path])
			when 'processes'      then YAML.dump(processes)
			when 'process_alive'  then process_alive(params[:pid]) ? '1' : '0'
			when 'kill_process'   then kill_process(params[:pid])
		else
			raise UnknownAction
		end
	end
end
