require File.dirname(__FILE__) + '/base'

describe Rush::FindBy do
	before do
		class Foo
			attr_accessor :bar

			def initialize(bar)
				@bar = bar
			end end

		@one = Foo.new('one')
		@two = Foo.new('two')
		@three = Foo.new('three')

		@list = [ @one, @two, @three ]
	end

	it "compare_or_match exact match success" do
		@list.compare_or_match('1', '1').should == true
	end

	it "compare_or_match exact match failure" do
		@list.compare_or_match('1', '2').should == false
	end

	it "compare_or_match regexp match success" do
		@list.compare_or_match('123', /2/).should == true
	end

	it "compare_or_match regexp match failure" do
		@list.compare_or_match('123', /x/).should == false
	end

	it "find_by_ extact match" do
		@list.find_by_bar('two').should == @two
	end

	it "find_by_ regexp match" do
		@list.find_by_bar(/.hree/).should == @three
	end

	it "find_all_by_ exact match" do
		@list.find_all_by_bar('one').should == [ @one ]
	end

	it "find_all_by_ regexp match" do
		@list.find_all_by_bar(/^...$/).should == [ @one, @two ]
	end

	it "find_by_ with field not recognized by objects raises no errors" do
		@list.find_by_nothing('x')
	end

	it "raises NoMethodError for things other than find_by" do
		lambda { @list.does_not_exist }.should raise_error(NoMethodError)
	end
end
