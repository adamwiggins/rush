require File.dirname(__FILE__) + '/base'

describe Rush::Connection::Local do
	before(:each) do
		@sandbox_dir = "/tmp/rush_spec.#{Process.pid}"
		system "rm -rf #{@sandbox_dir}; mkdir -p #{@sandbox_dir}"

		@con = Rush::Connection::Local.new
	end

	after(:each) do
		system "rm -rf #{@sandbox_dir}"
	end

	it "receive -> write_file(file, contents)" do
		@con.stub!(:write_file)
		@con.should_receive(:write_file).with('file', 'contents')
		@con.receive(:action => 'write_file', :full_path => 'file', :payload => 'contents')
	end

	it "receive -> file_contents(file)" do
		@con.stub!(:file_contents)
		@con.should_receive(:file_contents).with('file')
		@con.receive(:action => 'file_contents', :full_path => 'file')
	end

	it "receive -> destroy(file or dir)" do
		@con.stub!(:destroy)
		@con.should_receive(:destroy).with('file')
		@con.receive(:action => 'destroy', :full_path => 'file')
	end

	it "receive -> create_dir(path)" do
		@con.stub!(:create_dir)
		@con.should_receive(:create_dir).with('dir')
		@con.receive(:action => 'create_dir', :full_path => 'dir')
	end

	it "receive -> rename(path, name, new_name)" do
		@con.stub!(:rename)
		@con.should_receive(:rename).with('path', 'name', 'new_name')
		@con.receive(:action => 'rename', :path => 'path', :name => 'name', :new_name => 'new_name')
	end

	it "receive -> copy(src, dst)" do
		@con.stub!(:copy)
		@con.should_receive(:copy).with('src', 'dst')
		@con.receive(:action => 'copy', :src => 'src', :dst => 'dst')
	end

	it "receive -> unknown action exception" do
		lambda { @con.receive(:action => 'does_not_exist') }.should raise_error(Rush::Connection::Local::UnknownAction)
	end

	it "write_file writes contents to a file" do
		fname = "#{@sandbox_dir}/a_file"
		data = "some data"
		@con.write_file(fname, data)
		File.read(fname).should == data
	end

	it "file_contents reads a file's contents" do
		fname = "#{@sandbox_dir}/a_file"
		system "echo -n stuff > #{fname}"
		@con.file_contents(fname).should == "stuff"
	end

	it "destroy to destroy a file or dir" do
		fname = "#{@sandbox_dir}/delete_me"
		system "touch #{fname}"
		@con.destroy(fname)
		File.exists?(fname).should be_false
	end

	it "create_dir creates a directory" do
		fname = "#{@sandbox_dir}/a/b/c/"
		@con.create_dir(fname)
		File.directory?(fname).should be_true
	end

	it "rename to rename entries within a dir" do
		system "touch #{@sandbox_dir}/a"
		@con.rename(@sandbox_dir, 'a', 'b')
		File.exists?("#{@sandbox_dir}/a").should be_false
		File.exists?("#{@sandbox_dir}/b").should be_true
	end

	it "copy to copy an entry to another dir" do
		system "mkdir #{@sandbox_dir}/subdir"
		system "touch #{@sandbox_dir}/a"
		@con.copy("#{@sandbox_dir}/a", "#{@sandbox_dir}/subdir")
		File.exists?("#{@sandbox_dir}/a").should be_true
		File.exists?("#{@sandbox_dir}/subdir/a").should be_true
	end
end
