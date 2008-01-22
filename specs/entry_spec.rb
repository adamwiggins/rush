require File.dirname(__FILE__) + '/base'

describe Rush::Entry do
	before(:each) do
		@sandbox_dir = "/tmp/rush_spec.#{Process.pid}"
		system "rm -rf #{@sandbox_dir}; mkdir -p #{@sandbox_dir}"

		@filename = "#{@sandbox_dir}/test_file"
		system "touch #{@filename}"

		@entry = Rush::Entry.new(@filename)
	end

	after(:each) do
		system "rm -rf #{@sandbox_dir}"
	end

	it "knows its name" do
		@entry.name.should eql(File.basename(@filename))
	end

	it "knows its parent directory" do
		@entry.parent.should be_kind_of(Rush::Dir)
		@entry.parent.name.should eql(File.basename(@sandbox_dir))
		@entry.parent.full_path.should eql(@sandbox_dir)
	end

	it "knows its created_at time" do
		@entry.created_at.should eql(File.stat(@filename).ctime)
	end

	it "knows its last_modified time" do
		@entry.last_modified.should eql(File.stat(@filename).mtime)
	end

	it "knows its last_accessed time" do
		@entry.last_accessed.should eql(File.stat(@filename).atime)
	end

	it "can rename itself" do
		new_file = "test2"

		@entry.rename(new_file)

		File.exists?(@filename).should be_false
		File.exists?("#{@sandbox_dir}/#{new_file}").should be_true
	end

	it "can't rename itself if another file already exists with that name" do
		new_file = "test3"
		system "touch #{@sandbox_dir}/#{new_file}"

		lambda { @entry.rename(new_file) }.should raise_error(Rush::Entry::NameAlreadyExists)
	end

	it "can move itself to another dir" do
		newdir = "#{@sandbox_dir}/newdir"
		system "mkdir -p #{newdir}"

		dst = Rush::Dir.new(newdir)
		@entry.move_to(dst)

		File.exists?(@filename).should be_false
		File.exists?("#{newdir}/#{@entry.name}").should be_true
	end
end
