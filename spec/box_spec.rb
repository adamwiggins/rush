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
end
