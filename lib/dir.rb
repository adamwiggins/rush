module Rush
	class Dir < Entry
		def dir?
			true
		end

		def full_path
			"#{super}/"
		end

		def files
			list = []
			::Dir.open(full_path).each do |fname|
				full_fname = "#{full_path}/#{fname}"
				next if ::File.directory? full_fname
				list << Rush::File.new(full_fname, box)
			end
			list
		end

		def dirs
			list = []
			::Dir.open(full_path).each do |fname|
				next if fname == '.' or fname == '..'
				full_fname = "#{full_path}/#{fname}"
				next unless ::File.directory? full_fname
				list << Rush::Dir.new(full_fname, box)
			end
			list
		end

		def contents
			dirs + files
		end

		def [](key)
			if key.kind_of? Regexp
				find_by_regexp(key)
			else
				key = key.to_s
				if key == '**'
					files_flattened
				elsif key.slice(0, 3) == '**/'
					find_by_doubleglob(key)
				elsif key.match(/\*/)
					find_by_glob(key)
				else
					find_by_name(key)
				end
			end
		end

		def find_by_name(name)
			Rush::Entry.factory("#{full_path}/#{name}", box)
		end

		def find_by_glob(glob)
			find_by_regexp(self.class.glob_to_regexp(glob))
		end

		def find_by_regexp(pattern)
			contents.select do |entry|
				entry.name.match(pattern)
			end
		end

		def self.glob_to_regexp(glob)
			Regexp.new("^" + glob.gsub(/\./, '\\.').gsub(/\*/, '.*') + "$")
		end

		def files_flattened
			dirs.inject(files) do |all, subdir|
				all += subdir.files_flattened
			end
		end

		def dirs_flattened
			dirs.inject(dirs) do |all, subdir|
				all += subdir.dirs_flattened
			end
		end

		def find_by_doubleglob(doubleglob)
			glob = doubleglob.gsub(/^\*\*\//, '')

			find_by_glob(glob) +
			dirs_flattened.inject([]) do |all, subdir|
				all += subdir.find_by_glob(glob)
			end
		end

		def make_entries(filenames)
			filenames.map do |fname|
				Rush::Entry.factory("#{full_path}/#{fname}")
			end
		end

		def create_file(name)
			file = Rush::File.new("#{full_path}/#{name}", box)
			file.write('')
			file
		end

		def create_dir(name)
			newdir = Rush::Dir.new("#{full_path}/#{name}", box)
			system "mkdir -p #{newdir.full_path}"
			newdir
		end

		def create
			connection.create_dir(full_path)
			self
		end

		def size
			`du -sb #{full_path}`.match(/(\d+)/)[1].to_i
		end

		def nonhidden_dirs
			dirs.select do |dir|
				!dir.hidden?
			end
		end

		def nonhidden_files
			files.select do |file|
				!file.hidden?
			end
		end

		def ls
			out = [ "#{self}" ]
			nonhidden_dirs.each do |dir|
				out << "  #{dir.name}+"
			end
			nonhidden_files.each do |file|
				out << "  #{file.name}"
			end
			out.join("\n")
		end

		def rake(*args)
			system "cd #{full_path}; rake #{args.join(' ')}"
		end

		def git(*args)
			system "cd #{full_path}; git #{args.join(' ')}"
		end

		include Rush::Commands

		def entries
			contents
		end
	end
end
