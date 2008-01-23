require File.dirname(__FILE__) + '/base'

describe Rush::Dir do
	before(:each) do
		@sandbox_dir = "/tmp/rush_spec.#{Process.pid}"
		system "rm -rf #{@sandbox_dir}; mkdir -p #{@sandbox_dir}"

		@dirname = "#{@sandbox_dir}/test_dir"
		system "mkdir -p #{@dirname}"

		@dir = Rush::Dir.new(@dirname)
	end

	after(:each) do
		system "rm -rf #{@sandbox_dir}"
	end

	it "is a child of Rush::Entry" do
		@dir.should be_kind_of(Rush::Entry)
	end

	it "can create a new file" do
		newfile = @dir.create_file('one.txt')
		newfile.name.should == 'one.txt'
		newfile.parent.should == @dir
	end

	it "can create a new subdir" do
		newfile = @dir.create_dir('two')
		newfile.name.should == 'two'
		newfile.parent.should == @dir
	end

	it "lists files" do
		@dir.create_file('a')
		@dir.files.should == [ Rush::File.new("#{@dirname}/a") ]
	end

	it "lists dirs" do
		@dir.create_dir('b')
		@dir.files.should == [ Rush::Dir.new("#{@dirname}/b") ]
	end

	it "knows its size in bytes, which includes its contents recursively" do
	end

	it "can destroy itself when empty" do
	end

	it "can destroy itself when not empty" do
	end
end
