require_relative 'base'

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
		expect(@list.compare_or_match('1', '1')).to eq true
	end

	it "compare_or_match exact match failure" do
		expect(@list.compare_or_match('1', '2')).to eq false
	end

	it "compare_or_match regexp match success" do
		expect(@list.compare_or_match('123', /2/)).to eq true
	end

	it "compare_or_match regexp match failure" do
		expect(@list.compare_or_match('123', /x/)).to eq false
	end

	it "find_by_ extact match" do
		expect(@list.find_by_bar('two')).to eq @two
	end

	it "find_by_ regexp match" do
		expect(@list.find_by_bar(/.hree/)).to eq @three
	end

	it "find_all_by_ exact match" do
		expect(@list.find_all_by_bar('one')).to eq [ @one ]
	end

	it "find_all_by_ regexp match" do
		expect(@list.find_all_by_bar(/^...$/)).to eq [ @one, @two ]
	end

	it "find_by_ with field not recognized by objects raises no errors" do
		@list.find_by_nothing('x')
	end

	it "raises NoMethodError for things other than find_by" do
		expect { @list.does_not_exist }.to raise_error(NoMethodError)
	end
end
