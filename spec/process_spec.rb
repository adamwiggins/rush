require File.dirname(__FILE__) + '/base'

describe Rush::Process do
	before(:each) do
		@pid = fork do
			sleep 999
		end
		@process = Rush::Process.list.detect { |p| p.pid == @pid }
	end

	after(:each) do
		system "kill -9 #{@pid}"
	end

	it "gets the list of all processes" do
		list = Rush::Process.list
		list.size.should > 5
		list.first.should be_kind_of(Rush::Process)
	end

	it "knows the pid" do
		@process.pid.should == @pid
	end

	it "knows the uid" do
		@process.uid.should == Process.uid
	end

	it "knows the executed binary" do
		@process.command.should == "(ruby)"
	end

	it "knows the command line" do
	end

	it "can kill itself" do
	end

	it "can kill itself even when wedged" do
	end
end
