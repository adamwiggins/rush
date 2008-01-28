require File.dirname(__FILE__) + '/base'

describe Rush::File do
	before(:each) do
		@sandbox_dir = "/tmp/rush_spec.#{Process.pid}"
		system "rm -rf #{@sandbox_dir}; mkdir -p #{@sandbox_dir}"

		@filename = "#{@sandbox_dir}/test_file"
		@contents = "1234"
		system "echo -n '#{@contents}' > #{@filename}"

		@file = Rush::File.new(@filename)
	end

	after(:each) do
		system "rm -rf #{@sandbox_dir}"
	end

	it "is a child of Rush::Entry" do
		@file.should be_kind_of(Rush::Entry)
	end

	it "is not a dir" do
		@file.should_not be_dir
	end

	it "knows its size in bytes" do
		@file.size.should eql(@contents.length)
	end

	it "can read its contents" do
		@file.contents.should eql(@contents)
	end

	it "can write new contents" do
		@file.write('write test')
		@file.contents.should eql('write test')
	end

	it "find-in-file replace" do
		@file.replace_contents!(/\d/, 'x')
		@file.contents.should eql('xxxx')
	end

	it "can destroy itself" do
		@file.destroy
		::File.exists?(@filename).should be_false
	end
end
