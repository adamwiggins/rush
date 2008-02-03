require File.dirname(__FILE__) + '/base'

describe Rush::Connection::Local do
	before(:each) do
		@sandbox_dir = "/tmp/rush_spec.#{Process.pid}"
		system "rm -rf #{@sandbox_dir}; mkdir -p #{@sandbox_dir}"

		@con = Rush::Connection::Remote.new('spec.example.com')
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
		@con.should_receive(:transmit).with(:action => 'index', :base_path => 'base_path', :pattern => '.*').and_return("")
		@con.index('base_path', '.*')
	end

	it "transmits index_tree" do
		@con.stub!(:transmit)
		@con.should_receive(:transmit).with(:action => 'index_tree', :base_path => 'base_path').and_return("")
		@con.index_tree('base_path')
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

	it "gets the real host and port from the tunnels list" do
		mock_config do |config|
			@con.stub!(:config).and_return(config)
			@con.stub!(:establish_tunnel)
			config.tunnels_file.write("#{@con.host}:123")
			@con.real_host.should == 'localhost'
			@con.real_port.should == 123
		end
	end

	it "calls establish_tunnel when there is no tunnel" do
		mock_config do |config|
			@con.stub!(:config).and_return(config)
			@con.stub!(:establish_tunnel)
			@con.should_receive(:establish_tunnel)
			@con.real_host
		end
	end

	it "picks the first port number when there are no tunnels yet" do
		mock_config do |config|
			@con.stub!(:config).and_return(config)
			@con.next_available_port.should == 7771
		end
	end

	it "picks the next port number when there is already a tunnel" do
		mock_config do |config|
			@con.stub!(:config).and_return(config)
			config.tunnels_file.write("#{@con.host}:7771")
			@con.next_available_port.should == 7772
		end
	end
end
