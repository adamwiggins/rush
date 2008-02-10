require File.dirname(__FILE__) + '/base'

describe Rush::SshTunnel do
	before(:each) do
		@tunnel = Rush::SshTunnel.new('spec.example.com')
	end

	it "gets the real host and port from the tunnels list" do
		mock_config do |config|
			@tunnel.stub!(:config).and_return(config)
			@tunnel.stub!(:establish_tunnel)
			config.tunnels_file.write("#{@tunnel.host}:123")
			@tunnel.host.should == 'localhost'
			@tunnel.port.should == 123
		end
	end

	it "calls establish_tunnel when there is no tunnel" do
		mock_config do |config|
			@tunnel.stub!(:config).and_return(config)
			@tunnel.should_receive(:establish_tunnel)
			@tunnel.port
		end
	end

	it "picks the first port number when there are no tunnels yet" do
		mock_config do |config|
			@tunnel.stub!(:config).and_return(config)
			@tunnel.next_available_port.should == 7771
		end
	end

	it "picks the next port number when there is already a tunnel" do
		mock_config do |config|
			@tunnel.stub!(:config).and_return(config)
			config.tunnels_file.write("#{@tunnel.host}:7771")
			@tunnel.next_available_port.should == 7772
		end
	end
end
