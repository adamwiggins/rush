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
		@tunnel.should_receive(:ensure_still_alive)
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
		@tunnel.should_receive(:port).exactly(0).times.and_return('7771')   # avoid infinite loop
		@tunnel.establish_tunnel
		@tunnel.config.tunnels_file.contents.should == "spec.example.com:7771\n"
	end

	it "converts instance vars to options hash for ssh_tunnel_command" do
		@tunnel.instance_eval("@port = 1234")
		@tunnel.tunnel_options.should == {
			:local_port => 1234,
			:remote_port => 7770,
			:ssh_host => 'spec.example.com',
			:stall_command => 'sleep 9000'
		}
	end

	it "constructs the bash ssh command from the options hash" do
		@tunnel.should_receive(:tunnel_options).at_least(:once).and_return(
			:local_port => 123,
			:remote_port => 456,
			:ssh_host => 'example.com',
			:stall_command => 'stall'
		)
		@tunnel.ssh_tunnel_command.should == "ssh -f -L 123:127.0.0.1:456 example.com \"stall\""
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

	it "ensure_still_alive sets up from scratch if the tunnel is no longer alive" do
		@tunnel.should_receive(:tunnel_alive?).and_return(false)
		@tunnel.should_receive(:setup_everything)
		@tunnel.ensure_still_alive
	end

	it "tunnel_alive? checks whether a tunnel is still up" do
		@tunnel.should_receive(:tunnel_count_command).and_return("echo 1")
		@tunnel.tunnel_alive?.should be_true
	end

	it "tunnel_count_command greps ps to find the ssh tunnel" do
		@tunnel.should_receive(:ssh_tunnel_command_without_stall).and_return('ssh command')
		command = @tunnel.tunnel_count_command
		command.should match(/ps/)
		command.should match(/grep/)
		command.should match(/ssh command/)
	end
end
