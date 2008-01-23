require File.dirname(__FILE__) + '/base'

describe Rush::Process do
	before(:each) do
		@process = Rush::Process.list.detect { |p| p.pid == Process.pid }
	end

	after(:each) do
	end

	it "gets the list of all processes" do
		list = Rush::Process.list
		list.size.should > 0
		list.first.should be_kind_of(Rush::Process)
		list.first.pid.should > 0
	end

	it "knows the pid" do
		@process.pid.should == Process.pid
	end

	it "knows the uid" do
		@process.uid.should == Process.uid
	end

	it "knows the executed binary" do
	end

	it "knows the command line" do
	end

	it "can kill itself" do
	end

	it "can kill itself even when wedged" do
	end
end
