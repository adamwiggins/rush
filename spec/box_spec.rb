require File.dirname(__FILE__) + '/base'

describe Rush::Box do
	before do
		@sandbox_dir = "/tmp/rush_spec.#{Process.pid}"
		system "rm -rf #{@sandbox_dir}; mkdir -p #{@sandbox_dir}"

		@box = Rush::Box.new('localhost')
	end

	after do
		system "rm -rf #{@sandbox_dir}"
	end

	it "looks up entries with [] syntax" do
		@box['/'].should == Rush::Dir.new('/', @box)
	end

	it "looks up processes" do
		@box.connection.should_receive(:processes).and_return([ { :pid => 123 } ])
		@box.processes.should == [ Rush::Process.new({ :pid => 123 }, @box) ]
	end

	it "executes bash commands" do
		@box.connection.should_receive(:bash).with('cmd', nil).and_return('output')
		@box.bash('cmd').should == 'output'
	end

	it "executes bash commands with an optional user" do
		@box.connection.should_receive(:bash).with('cmd', 'user')
		@box.bash('cmd', :user => 'user')
	end

	it "builds a script of environment variables to prefix the bash command" do
		@box.command_with_environment('cmd', { :a => 'b' }).should == "export a='b'\ncmd"
	end

	it "sets the environment variables from the provided hash" do
		@box.connection.stub!(:bash)
		@box.should_receive(:command_with_environment).with('cmd', { 1 => 2 })
		@box.bash('cmd', :env => { 1 => 2 })
	end

	it "checks the connection to determine if it is alive" do
		@box.connection.should_receive(:alive?).and_return(true)
		@box.should be_alive
	end

	it "establish_connection to set up the connection manually" do
		@box.connection.should_receive(:ensure_tunnel)
		@box.establish_connection
	end

	it "establish_connection can take a hash of options" do
		@box.connection.should_receive(:ensure_tunnel).with(:timeout => :infinite)
		@box.establish_connection(:timeout => :infinite)
	end
end
