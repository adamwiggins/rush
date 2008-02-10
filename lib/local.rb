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

	def index(base_path, pattern)
		pattern = pattern and pattern.length > 0 ? Regexp.new(pattern) : nil

		dirs = []
		files = []
		::Dir.open(base_path).each do |fname|
			next if fname == '.' or fname == '..'

			next unless pattern.nil? or fname.match(pattern)

			full_fname = "#{base_path}/#{fname}"
			if ::File.directory? full_fname
				dirs << fname + "/"
			else
				files << fname
			end
		end
		dirs + files
	end

	def index_tree(root, pattern=nil, dir=nil)
		pattern = pattern and pattern.length > 0 ? Regexp.new(pattern) : nil

		full_dir = "#{root}/#{dir || ''}"

		entries = []
		::Dir.open(full_dir).each do |fname|
			next if fname.slice(0, 1) == '.'

			path = (dir ? "#{dir}/" : "") + fname

			if ::File.directory? "#{root}/#{path}"
				entries << path + "/" if pattern.nil? or fname.match(pattern)
				entries += index_tree(root, pattern, path)
			else
				entries << path if pattern.nil? or fname.match(pattern)
			end
		end
		entries.sort
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
			when 'index'          then index(params[:base_path], params[:pattern]).join("\n") + "\n"
			when 'index_tree'     then index_tree(params[:base_path], params[:pattern]).join("\n") + "\n"
			when 'stat'           then YAML.dump(stat(params[:full_path]))
			when 'size'           then size(params[:full_path])
		else
			raise UnknownAction
		end
	end
end
