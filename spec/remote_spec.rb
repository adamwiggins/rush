require File.dirname(__FILE__) + '/base'

describe Rush::Connection::Local do
	before do
		@sandbox_dir = "/tmp/rush_spec.#{Process.pid}"
		system "rm -rf #{@sandbox_dir}; mkdir -p #{@sandbox_dir}"

		@con = Rush::Connection::Remote.new('spec.example.com')
	end

	after do
		system "rm -rf #{@sandbox_dir}"
	end

	it "transmits write_file" do
		@con.should_receive(:transmit).with(:action => 'write_file', :full_path => 'file', :payload => 'contents')
		@con.write_file('file', 'contents')
	end

	it "transmits append_to_file" do
		@con.should_receive(:transmit).with(:action => 'append_to_file', :full_path => 'file', :payload => 'contents')
		@con.append_to_file('file', 'contents')
	end

	it "transmits file_contents" do
		@con.should_receive(:transmit).with(:action => 'file_contents', :full_path => 'file').and_return('contents')
		@con.file_contents('file').should == 'contents'
	end

	it "transmits destroy" do
		@con.should_receive(:transmit).with(:action => 'destroy', :full_path => 'file')
		@con.destroy('file')
	end

	it "transmits purge" do
		@con.should_receive(:transmit).with(:action => 'purge', :full_path => 'dir')
		@con.purge('dir')
	end

	it "transmits create_dir" do
		@con.should_receive(:transmit).with(:action => 'create_dir', :full_path => 'file')
		@con.create_dir('file')
	end

	it "transmits rename" do
		@con.should_receive(:transmit).with(:action => 'rename', :path => 'path', :name => 'name', :new_name => 'new_name')
		@con.rename('path', 'name', 'new_name')
	end

	it "transmits copy" do
		@con.should_receive(:transmit).with(:action => 'copy', :src => 'src', :dst => 'dst')
		@con.copy('src', 'dst')
	end

	it "transmits read_archive" do
		@con.should_receive(:transmit).with(:action => 'read_archive', :full_path => 'full_path').and_return('archive data')
		@con.read_archive('full_path').should == 'archive data'
	end

	it "transmits write_archive" do
		@con.should_receive(:transmit).with(:action => 'write_archive', :dir => 'dir', :payload => 'archive')
		@con.write_archive('archive', 'dir')
	end

	it "transmits index" do
		@con.should_receive(:transmit).with(:action => 'index', :base_path => 'base_path', :glob => '*').and_return("1\n2\n")
		@con.index('base_path', '*').should == %w(1 2)
	end

	it "transmits stat" do
		@con.should_receive(:transmit).with(:action => 'stat', :full_path => 'full_path').and_return(YAML.dump(1 => 2))
		@con.stat('full_path').should == { 1 => 2 }
	end

	it "transmits set_access" do
		@con.should_receive(:transmit).with(:action => 'set_access', :full_path => 'full_path', :user => 'joe', :user_read => 1)
		@con.set_access('full_path', :user => 'joe', :user_read => 1)
	end

	it "transmits size" do
		@con.should_receive(:transmit).with(:action => 'size', :full_path => 'full_path').and_return("123")
		@con.size('full_path').should == 123
	end

	it "transmits processes" do
		@con.should_receive(:transmit).with(:action => 'processes').and_return(YAML.dump([ { :pid => 1 } ]))
		@con.processes.should == [ { :pid => 1 } ]
	end

	it "transmits process_alive" do
		@con.should_receive(:transmit).with(:action => 'process_alive', :pid => 123).and_return(true)
		@con.process_alive(123).should == true
	end

	it "transmits kill_process" do
		@con.should_receive(:transmit).with(:action => 'kill_process', :pid => 123, :payload => YAML.dump(:wait => 10))
		@con.kill_process(123, :wait => 10)
	end

	it "transmits bash" do
		@con.should_receive(:transmit).with(:action => 'bash', :payload => 'cmd', :user => 'user', :background => 'bg').and_return('output')
		@con.bash('cmd', 'user', 'bg').should == 'output'
	end

	it "an http result code of 401 raises NotAuthorized" do
		lambda { @con.process_result("401", "") }.should raise_error(Rush::NotAuthorized)
	end

	it "an http result code of 400 raises the exception passed in the result body" do
		@con.stub!(:parse_exception).and_return(Rush::DoesNotExist, "message")
		lambda { @con.process_result("400", "") }.should raise_error(Rush::DoesNotExist)
	end

	it "an http result code of 501 (or anything other than the other defined codes) raises FailedTransmit" do
		lambda { @con.process_result("501", "") }.should raise_error(Rush::FailedTransmit)
	end

	it "parse_exception takes the class from the first line and the message from the second" do
		@con.parse_exception("Rush::DoesNotExist\nthe message\n").should == [ Rush::DoesNotExist, "the message" ]
	end

	it "parse_exception rejects unrecognized exceptions" do
		lambda { @con.parse_exception("NotARushException\n") }.should raise_error
	end

	it "passes through ensure_tunnel" do
		@con.tunnel.should_receive(:ensure_tunnel)
		@con.ensure_tunnel
	end

	it "is alive if the box is responding to commands" do
		@con.should_receive(:index).and_return(:dummy)
		@con.should be_alive
	end

	it "not alive if an attempted command throws an exception" do
		@con.should_receive(:index).and_raise(RuntimeError)
		@con.should_not be_alive
	end
end
