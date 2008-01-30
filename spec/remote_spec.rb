require File.dirname(__FILE__) + '/base'

describe Rush::Connection::Local do
	before(:each) do
		@sandbox_dir = "/tmp/rush_spec.#{Process.pid}"
		system "rm -rf #{@sandbox_dir}; mkdir -p #{@sandbox_dir}"

		@con = Rush::Connection::Remote.new('localhost')
	end

	after(:each) do
		system "rm -rf #{@sandbox_dir}"
	end

	it "transmits write_file" do
		@con.stub!(:transmit)
		@con.should_receive(:transmit).with(:action => 'write_file', :full_path => 'file', :payload => 'contents')
		@con.write_file('file', 'contents')
	end

	it "transmits file_contents" do
		@con.stub!(:transmit)
		@con.should_receive(:transmit).with(:action => 'file_contents', :full_path => 'file')
		@con.file_contents('file')
	end

	it "transmits destroy" do
		@con.stub!(:transmit)
		@con.should_receive(:transmit).with(:action => 'destroy', :full_path => 'file')
		@con.destroy('file')
	end

	it "transmits create_dir" do
		@con.stub!(:transmit)
		@con.should_receive(:transmit).with(:action => 'create_dir', :full_path => 'file')
		@con.create_dir('file')
	end

	it "transmits rename" do
		@con.stub!(:transmit)
		@con.should_receive(:transmit).with(:action => 'rename', :path => 'path', :name => 'name', :new_name => 'new_name')
		@con.rename('path', 'name', 'new_name')
	end

	it "transmits copy" do
		@con.stub!(:transmit)
		@con.should_receive(:transmit).with(:action => 'copy', :src => 'src', :dst => 'dst')
		@con.copy('src', 'dst')
	end

	it "transmits read_archive" do
		@con.stub!(:transmit)
		@con.should_receive(:transmit).with(:action => 'read_archive', :full_path => 'full_path')
		@con.read_archive('full_path')
	end

	it "transmits write_archive" do
		@con.stub!(:transmit)
		@con.should_receive(:transmit).with(:action => 'write_archive', :dir => 'dir', :payload => 'archive')
		@con.write_archive('archive', 'dir')
	end

	it "transmits index" do
		@con.stub!(:transmit)
		@con.should_receive(:transmit).with(:action => 'index', :full_path => 'full_path').and_return("")
		@con.index('full_path')
	end

	it "transmits stat" do
		@con.stub!(:transmit)
		@con.should_receive(:transmit).with(:action => 'stat', :full_path => 'full_path').and_return("")
		@con.stat('full_path')
	end

	it "transmits size" do
		@con.stub!(:transmit)
		@con.should_receive(:transmit).with(:action => 'size', :full_path => 'full_path').and_return("")
		@con.size('full_path')
	end
end
