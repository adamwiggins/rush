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

	it "throws an exception when the ssh shell command fails" do
	end
end
