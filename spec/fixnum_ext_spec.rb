require File.dirname(__FILE__) + '/base'

describe Fixnum do
	before do
		@num = 2
	end

	it "counts kb" do
		@num.kb.should == 2*1024
	end

	it "counts mb" do
		@num.mb.should == 2*1024*1024
	end

	it "counts gb" do
		@num.gb.should == 2*1024*1024*1024
	end
end
