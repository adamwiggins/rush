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
		system "mkdir -p #{@dir.full_path}/b"
		@dir.dirs.should == [ Rush::Dir.new("#{@dirname}/b") ]
	end

	it "lists combined files and dirs" do
		@dir.create_file('c')
		@dir.create_dir('d')
		@dir.contents.size.should == 2
	end

	it "find_by_name finds a single entry in the contents" do
		file = @dir.create_file('one.rb')
		@dir.find_by_name('one.rb').should == file
	end

	it "converts a glob to a regexp" do
		Rush::Dir.glob_to_regexp('*.rb').should == /^.*\.rb$/
		Rush::Dir.glob_to_regexp('*x*').should == /^.*x.*$/
	end

	it "find_by_glob finds a list of entries by wildcard" do
		file1 = @dir.create_file('one.rb')
		file2 = @dir.create_file('two.txt')
		@dir.find_by_glob('*.rb').should == [ file1 ]
	end

	it "find_by_regexp finds a list of entries by pattern" do
		file1 = @dir.create_file('red')
		file2 = @dir.create_file('blue2')
		@dir.find_by_regexp(/\d$/).should == [ file2 ]
	end

	it "find_subitem finds entries in a subdirectory" do
		file = @dir.create_dir('a/b').create_file('c')
		@dir.find_subitem('a/b/c').should == file
	end

	it "maps [] to find_by_name" do
		@dir.stub!(:find_by_name)
		@dir.should_receive(:find_by_name).once
		@dir['one']
	end

	it "maps [] with a wildcard character to find_by_glob" do
		@dir.stub!(:find_by_glob)
		@dir.should_receive(:find_by_glob).once
		@dir['*']
	end

	it "maps [] with a regexp to find_by_regexp" do
		@dir.stub!(:find_by_regexp)
		@dir.should_receive(:find_by_regexp).once
		@dir[/pat/]
	end

	it "maps [] to find_subitem when it references subdirs" do
		@dir.stub!(:find_subitem)
		@dir.should_receive(:find_subitem).once
		@dir['a/b/c']
	end

	it "lists flattened files (in all nested subdirectories)" do
		@dir.create_file('1')
		@dir.create_dir('2/3').create_file('4')
		@dir.create_dir('a/b/c').create_file('d')
		@dir.files_flattened.should == [ @dir['1'], @dir['2/3/4'], @dir['a/b/c/d'] ]
	end

	xit "can glob **/ to get all nested contents" do
		@dir.create_file('1.rb')
		@dir.create_file('ignore.txt')
		@dir.create_dir('2').create_file('3.rb')
		@dir.create_dir('a/b').create_file('c.rb')
		@dir['**/*.rb'].should == [ @dir['1.rb'], @dir['2/3.rb'], @dir['a/b/c.rb' ] ]
	end

	it "knows its size in bytes, which includes its contents recursively" do
	end

	it "can destroy itself when empty" do
		@dir.destroy
	end

	it "can destroy itself when not empty" do
		@dir.create_dir('a').create_file('b').write('c')
		@dir.destroy
	end
end
