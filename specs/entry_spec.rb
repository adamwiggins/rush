require File.dirname(__FILE__) + '/base'

describe Rush::Entry do
	before(:each) do
		@sandbox_dir = "/tmp/rush_spec.#{Process.pid}"
		system "mkdir -p #{@sandbox_dir}"

		@file = "/#{@sandbox_dir}/rush_spec.#{@id}"
		system "touch #{@file}"

		@entry = Rush::Entry.new(@file)
	end

	after(:each) do
		system "rm -f #{@file}"
	end

	it "knows its name" do
		@entry.name.should equal(File.basename(@file))
	end

	it "knows its parent directory" do
		@entry.parent.should be_kind_of(Rush::Dir)
		@entry.parent.name.should equal(File.basename(@sandbox_dir))
		@entry.parent.full_path.should equal(@sandbox_dir)
	end

	it "knows its created_at time" do
		@entry.created_at.should equal(File.stat(@file).ctime)
	end

	it "knows its last_modified time" do
		@entry.last_modified.should equal(File.stat(@file).mtime)
	end

	it "knows its last_accessed time" do
		@entry.last_accessed.should equal(File.stat(@file).atime)
	end

	it "can rename itself" do
		new_file = "rush_spec_2.#{@id}"

		@entry.rename(new_file)

		File.exists?(@file).should be_false
		File.exists?(new_file).should be_true
	end

	it "can move itself to another dir" do
		newdir = "#{@sandbox_dir}/newdir"
		system "mkdir -p #{newdir}"

		dst = Rush::Dir.new(newdir)
		@entry.move_to(dst)

		File.exists?(@file).should be_false
		File.exists?("#{newdir}/#{@entry.name}").should be_true
	end
end
