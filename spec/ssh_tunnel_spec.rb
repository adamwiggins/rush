require File.dirname(__FILE__) + '/base'

describe Rush::SshTunnel do
	before do
		@tunnel = Rush::SshTunnel.new('spec.example.com')
		@tunnel.stub!(:config).and_return(mock_config_start)
		@tunnel.stub!(:display)
	end

	after do
		mock_config_cleanup
	end

	it "ensure_tunnel sets everything up for the tunnel when one does not already exist" do
		@tunnel.should_receive(:push_credentials)
		@tunnel.should_receive(:launch_rushd)
		@tunnel.should_receive(:establish_tunnel)
		@tunnel.ensure_tunnel
	end

	it "tunnel host is always local" do
		@tunnel.host.should == 'localhost'
	end

	it "existing tunnel is used when it is specified in the tunnels file" do
		@tunnel.config.tunnels_file.write "spec.example.com:4567\n"
		@tunnel.port.should == 4567
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
		@tunnel.establish_tunnel
		@tunnel.config.tunnels_file.contents.should == "spec.example.com:7771\n"
	end

	it "constructs the bash ssh command from an options hash" do
		@tunnel.build_tunnel_args({
			:local_port => 123,
			:remote_port => 456,
			:ssh_host => 'example.com',
			:stall_command => 'stall'
		}).should == "-L 123:127.0.0.1:456 example.com 'stall' &"
	end

	it "push_credentials uses ssh to append to remote host's passwords file" do
		@tunnel.should_receive(:ssh_append_to_credentials).and_return(true)
		@tunnel.push_credentials
	end

	it "launches rushd on the remote host via ssh" do
		@tunnel.should_receive(:ssh) do |cmd|
			cmd.should match(/rushd/)
		end
		@tunnel.launch_rushd
	end
end
