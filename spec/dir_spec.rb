require File.dirname(__FILE__) + '/base'

describe Rush::Dir do
	before do
		@sandbox_dir = "/tmp/rush_spec.#{Process.pid}"
		system "rm -rf #{@sandbox_dir}; mkdir -p #{@sandbox_dir}"

		@dirname = "#{@sandbox_dir}/test_dir/"
		system "mkdir -p #{@dirname}"

		@dir = Rush::Dir.new(@dirname)
	end

	after do
		system "rm -rf #{@sandbox_dir}"
	end

	it "is a child of Rush::Entry" do
		@dir.should be_kind_of(Rush::Entry)
	end

	it "can create itself, returning itself" do
		system "rm -rf #{@sandbox_dir}"
		@dir.create.should == @dir
		File.directory?(@dir.full_path).should be_true
	end

	it "can create a new file" do
		newfile = @dir.create_file('one.txt')
		newfile.name.should == 'one.txt'
		newfile.parent.should == @dir
	end

	it "can create a new subdir" do
		newfile = @dir['two/'].create
		newfile.name.should == 'two'
		newfile.parent.should == @dir
	end

	it "find_by_name finds a single entry in the contents" do
		file = @dir.create_file('one.rb')
		@dir.find_by_name('one.rb').should == file
	end

	it "find_by_glob finds a list of entries by wildcard" do
		file1 = @dir.create_file('one.rb')
		file2 = @dir.create_file('two.txt')
		@dir.find_by_glob('*.rb').should == [ file1 ]
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
		@dir['c'].create
		@dir['d/'].create
		@dir.contents.size.should == 2
	end

	it "fetches the entry_tree of all contents recursively" do
		@dir['a/'].create['b/'].create['c'].create
		@dir.entries_tree.should == @dir.make_entries(%w(a/ a/b/ a/b/c))
	end

	it "maps [] to find_by_name" do
		@dir.should_receive(:find_by_name).once
		@dir['one']
	end

	it "maps [] with a wildcard character to find_by_glob" do
		@dir.should_receive(:find_by_glob).once
		@dir['*']
	end

	it "can use symbols or strings for [] access" do
		@dir.should_receive(:find_by_name).once.with('subdir')
		@dir[:subdir]
	end

	it "[] can return a file that has yet to be created" do
		@dir['not_yet'].class.should == Rush::File
	end

	it "makes a list of entries from an array of filenames" do
		@dir['a'].create
		@dir['b/c/'].create
		@dir.make_entries(%w(a b/c)).should == [ @dir['a'], @dir['b/c'] ]
	end

	it "lists flattened files from all nested subdirectories" do
		@dir['1'].create
		@dir['2/3/'].create['4'].create
		@dir['a/b/c/'].create['d'].create
		@dir.files_flattened.should == @dir.make_entries(%w(1 2/3/4 a/b/c/d))
	end

	it "lists flattened dirs from all nested subdirectories" do
		@dir.create_dir('1/2')
		@dir.dirs_flattened.should == @dir.make_entries(%w(1/ 1/2/))
	end

	it "** as a shortcut to flattened_files" do
		@dir['**'].should == @dir.files_flattened
	end

	it "**/ as a shortcut to flattened_files + regular globbing" do
		@dir.create_file('1.rb')
		@dir.create_file('ignore.txt')
		@dir.create_dir('2').create_file('3.rb')
		@dir.create_dir('a/b').create_file('c.rb')
		@dir['**/*.rb'].should == @dir.make_entries(%w(1.rb 2/3.rb a/b/c.rb))
	end

	it "lists nonhidden files" do
		@dir.create_file('show')
		@dir.create_file('.dont_show')
		@dir.nonhidden_files.should == @dir.make_entries(%w(show))
	end

	it "lists nonhidden dirs" do
		@dir.create_dir('show')
		@dir.create_dir('.dont_show')
		@dir.nonhidden_dirs.should == @dir.make_entries(%w(show/))
	end

	if !RUBY_PLATFORM.match(/darwin/)   # doesn't work on OS X 'cause du switches are different
		it "knows its size in bytes, which includes its contents recursively" do
			@dir.create_file('a').write('1234')
			@dir.size.should be(4096 + 4)
		end
	end

	it "can destroy itself when empty" do
		@dir.destroy
	end

	it "can destroy itself when not empty" do
		@dir.create_dir('a').create_file('b').write('c')
		@dir.destroy
	end

	it "can run a bash command within itself" do
		system "echo test > #{@dir.full_path}/file"
		@dir.bash("cat file").should == "test\n"
	end

	it "can run bash within directories with spaces" do
		@dir.create_dir('with space').create_file('file').write('test')
		@dir["with space/"].bash("cat file").should == "test"
	end

	it "passes bash options (e.g., :user) through to the box bash command" do
		@dir.should_receive(:bash).with('cmd', :opt1 => 1, :opt2 => 2)
		@dir.bash('cmd', :opt1 => 1, :opt2 => 2)
	end

end
