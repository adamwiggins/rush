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
end
