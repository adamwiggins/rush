require File.dirname(__FILE__) + '/base'

describe Rush::SshTunnel do
	before do
		@tunnel = Rush::SshTunnel.new('spec.example.com')
		@tunnel.stub!(:config).and_return(mock_config_start)
	end

	after do
		mock_config_cleanup
	end

	it "gets the real host and port from the tunnels list" do
		@tunnel.stub!(:establish_tunnel)
		@tunnel.config.tunnels_file.write("#{@tunnel.host}:123")
		@tunnel.host.should == 'localhost'
		@tunnel.port.should == 123
	end

	it "calls establish_tunnel when there is no tunnel" do
		@tunnel.stub!(:push_credentials)
		@tunnel.should_receive(:establish_tunnel)
		@tunnel.port
	end

	it "picks the first port number when there are no tunnels yet" do
		@tunnel.next_available_port.should == 7771
	end

	it "picks the next port number when there is already a tunnel" do
		@tunnel.config.tunnels_file.write("#{@tunnel.host}:7771")
		@tunnel.next_available_port.should == 7772
	end

	it "establishes a tunnel and saves it to ~/.rush/tunnels" do
		@tunnel.should_receive(:make_ssh_tunnel)
		@tunnel.stub!(:display)
		@tunnel.establish_tunnel
		@tunnel.config.tunnels_file.contents.should == "spec.example.com:7771\n"
	end

	it "constructs the bash ssh command from an options hash" do
		@tunnel.bash_ssh_command({
			:local_port => 123,
			:remote_port => 456,
			:ssh_host => 'example.com',
			:stall_command => 'stall'
		}).should == "ssh -L 123:127.0.0.1:456 example.com 'stall' &"
	end

	it "throws an exception when the ssh shell command fails" do
		@tunnel.should_receive(:bash_ssh_command).with({}).and_return("/bin/false")
		lambda { @tunnel.make_ssh_tunnel({}) }.should raise_error(Rush::SshTunnel::SshFailed)
		@tunnel.config.tunnels_file.contents_or_blank.should == ""
	end

	it "push_credentials uses ssh to append to remote host's passwords file" do
		@tunnel.should_receive(:ssh_append_to_credentials).and_return(true)
		@tunnel.push_credentials
	end
end
