require File.dirname(__FILE__) + '/base'

describe Rush::Box do
	before(:each) do
		@sandbox_dir = "/tmp/rush_spec.#{Process.pid}"
		system "rm -rf #{@sandbox_dir}; mkdir -p #{@sandbox_dir}"

		@box = Rush::Box.new('localhost')
	end

	after(:each) do
		system "rm -rf #{@sandbox_dir}"
	end

	it "looks up entries with [] syntax" do
		@box['/'].should == Rush::Dir.new('/')
	end

	it "executes a file write action" do
		fname = "#{@sandbox_dir}/test"
		@box.execute(:action => 'write', :full_path => fname, :payload => 'something')
		File.read(fname).should == 'something'
	end
end
