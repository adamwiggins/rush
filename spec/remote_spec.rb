require File.dirname(__FILE__) + '/base'

describe Rush::Connection::Local do
	before(:each) do
		@sandbox_dir = "/tmp/rush_spec.#{Process.pid}"
		system "rm -rf #{@sandbox_dir}; mkdir -p #{@sandbox_dir}"

		@con = Rush::Connection::Remote.new('localhost')
	end

	after(:each) do
		system "rm -rf #{@sandbox_dir}"
	end

	it "transmits write_file" do
		@con.stub!(:transmit)
		@con.should_receive(:transmit).with(:action => 'write_file', :full_path => 'file', :payload => 'contents')
		@con.write_file('file', 'contents')
	end

	it "transmits file_contents" do
		@con.stub!(:transmit)
		@con.should_receive(:transmit).with(:action => 'file_contents', :full_path => 'file')
		@con.file_contents('file')
	end

	it "transmits destroy" do
		@con.stub!(:transmit)
		@con.should_receive(:transmit).with(:action => 'destroy', :full_path => 'file')
		@con.destroy('file')
	end

	it "transmits create_dir" do
		@con.stub!(:transmit)
		@con.should_receive(:transmit).with(:action => 'create_dir', :full_path => 'file')
		@con.create_dir('file')
	end
end
