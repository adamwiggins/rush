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
		@box.connection.should_receive(:bash).with('cmd').and_return('output')
		@box.bash('cmd').should == 'output'
	end

	it "establish_connection to set up the connection manually" do
		@box.connection.should_receive(:ensure_tunnel)
		@box.establish_connection
	end
end
