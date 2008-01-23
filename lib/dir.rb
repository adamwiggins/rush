module Rush
	class Dir < Entry
		def files
			list = []
			::Dir.open(full_path).each do |fname|
				next if ::File.directory? fname
				list << Rush::File.new("#{full_path}/#{fname}")
			end
			list
		end

		def dirs
			list = []
			::Dir.open(full_path).each do |fname|
				next unless ::File.directory? fname
				list << Rush::Dir.new("#{full_path}/#{fname}")
			end
			list
		end

		def create_file(name)
			file = Rush::File.new("#{full_path}/#{name}")
			file.write('')
			file
		end

		def create_dir(name)
			newdir = Rush::Dir.new("#{full_path}/#{name}")
			system "mkdir -p #{newdir.full_path}"
			newdir
		end
	end
end
