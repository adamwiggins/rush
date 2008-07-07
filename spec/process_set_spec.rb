require File.dirname(__FILE__) + '/base'

describe Rush::ProcessSet do
	before do
		@process = mock('process')
		@set = Rush::ProcessSet.new([ @process ])
	end

	it "is Enumerable" do
		@set.select { |s| s == @process }.should == [ @process ]
	end

	it "defines size" do
		@set.size.should == 1
	end

	it "defines first" do
		@set.first.should == @process
	end

	it "is equal to sets with the same contents" do
		@set.should == Rush::ProcessSet.new([ @process ])
	end

	it "is equal to arrays with the same contents" do
		@set.should == [ @process ]
	end

	it "kills all processes in the set" do
		@process.should_receive(:kill)
		@set.kill
	end

	it "checks the alive? state of all processes in the set" do
		@process.should_receive(:alive?).and_return(true)
		@set.alive?.should == [ true ]
	end

	it "filters the set from a conditions hash and returns the filtered set" do
		@process.stub!(:pid).and_return(123)
		@set.filter(:pid => 123).first.should == @process
		@set.filter(:pid => 456).size.should == 0
	end

	it "filters with regexps if provided in the conditions" do
		@process.stub!(:command).and_return('foobaz')
		@set.filter(:command => /baz/).first.should == @process
		@set.filter(:command => /blerg/).size.should == 0
	end
end
