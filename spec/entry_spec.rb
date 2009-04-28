require File.dirname(__FILE__) + '/base'

describe Rush::Entry do
	before do
		@sandbox_dir = "/tmp/rush_spec.#{Process.pid}/"
		system "rm -rf #{@sandbox_dir}; mkdir -p #{@sandbox_dir}"

		@filename = "#{@sandbox_dir}/test_file"
		system "touch #{@filename}"

		@entry = Rush::Entry.new(@filename)
	end

	after do
		system "rm -rf #{@sandbox_dir}"
	end

	it "knows its name" do
		@entry.name.should == File.basename(@filename)
	end

	it "knows its parent dir" do
		@entry.parent.should be_kind_of(Rush::Dir)
		@entry.parent.name.should == File.basename(@sandbox_dir)
		@entry.parent.full_path.should == @sandbox_dir
	end

	it "cleans its pathname" do
		Rush::Entry.new('/a//b//c').full_path.should == '/a/b/c'
		Rush::Entry.new('/1/2/../3').full_path.should == '/1/3'
	end

	it "knows its changed_at time" do
		@entry.changed_at.should == File.stat(@filename).ctime
	end

	it "knows its last_modified time" do
		@entry.last_modified.should == File.stat(@filename).mtime
	end

	it "knows its last_accessed time" do
		@entry.last_accessed.should == File.stat(@filename).atime
	end

	it "considers itself equal to other instances with the same full path" do
		Rush::Entry.new('/not/the/same').should_not == @entry
		Rush::Entry.new(@entry.full_path).should == @entry
	end

	it "can rename itself" do
		new_file = "test2"

		@entry.rename(new_file)

		File.exists?(@filename).should be_false
		File.exists?("#{@sandbox_dir}/#{new_file}").should be_true
	end

	it "rename returns the renamed file" do
		@entry.rename('file2').should == @entry.parent['file2']
	end

	it "can't rename itself if another file already exists with that name" do
		new_file = "test3"
		system "touch #{@sandbox_dir}/#{new_file}"

		lambda { @entry.rename(new_file) }.should raise_error(Rush::NameAlreadyExists, /#{new_file}/)
	end

	it "can't rename itself to something with a slash in it" do
		lambda { @entry.rename('has/slash') }.should raise_error(Rush::NameCannotContainSlash, /slash/)
	end

	it "can duplicate itself within the directory" do
		@entry.duplicate('newfile').should == Rush::File.new("#{@sandbox_dir}/newfile")
	end

	it "can move itself to another dir" do
		newdir = "#{@sandbox_dir}/newdir"
		system "mkdir -p #{newdir}"

		dst = Rush::Dir.new(newdir)
		@entry.move_to(dst)

		File.exists?(@filename).should be_false
		File.exists?("#{newdir}/#{@entry.name}").should be_true
	end

	it "can copy itself to another directory" do
		newdir = "#{@sandbox_dir}/newdir"
		system "mkdir -p #{newdir}"

		dst = Rush::Dir.new(newdir)
		@copied_dir = @entry.copy_to(dst)

		File.exists?(@filename).should be_true
		File.exists?("#{newdir}/#{@entry.name}").should be_true

		@copied_dir.full_path.should == "#{@sandbox_dir}newdir/#{@entry.name}"
	end

	it "considers dotfiles to be hidden" do
		Rush::Entry.new("#{@sandbox_dir}/show").should_not be_hidden
		Rush::Entry.new("#{@sandbox_dir}/.dont_show").should be_hidden
	end

	it "is considered equal to entries with the same full path and on the same box" do
		same = Rush::Entry.new(@entry.full_path, @entry.box)
		@entry.should == same
	end

	it "is considered not equal to entries with the same full path on a different box" do
		same = Rush::Entry.new(@entry.full_path, Rush::Box.new('dummy'))
		@entry.should_not == same
	end

	it "can mimic another entry" do
		copy = Rush::Entry.new('abc', :dummy)
		copy.mimic(@entry)
		copy.path.should == @entry.path
	end

	it "can update the read access permission" do
		system "chmod 666 #{@filename}"
		@entry.access = { :user_can => :read }
		`ls -l #{@filename}`.should match(/^-r--------/)
	end

	it "reads the file permissions in the access hash" do
		system "chmod 640 #{@filename}"
		@entry.access.should == { :user_can_read => true, :user_can_write => true, :group_can_read => true }
	end
end
