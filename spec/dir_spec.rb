require_relative 'base'

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
		expect(@dir).to be_kind_of(Rush::Entry)
	end

	it "can create itself, returning itself" do
		system "rm -rf #{@sandbox_dir}"
		expect(@dir.create).to eq @dir
		expect(File.directory?(@dir.full_path)).to eq(true)
	end

	it "can create a new file" do
		newfile = @dir.create_file('one.txt')
		expect(newfile.name).to eq 'one.txt'
		expect(newfile.parent).to eq @dir
	end

	it "can create a new subdir" do
		newfile = @dir['two/'].create
		expect(newfile.name).to eq 'two'
		expect(newfile.parent).to eq @dir
	end

	it "find_by_name finds a single entry in the contents" do
		file = @dir.create_file('one.rb')
		expect(@dir.find_by_name('one.rb')).to eq file
	end

	it "find_by_glob finds a list of entries by wildcard" do
		file1 = @dir.create_file('one.rb')
		file2 = @dir.create_file('two.txt')
		expect(@dir.find_by_glob('*.rb')).to eq([file1])
	end

	it "lists files" do
		@dir.create_file('a')
		expect(@dir.files).to eq([Rush::File.new("#{@dirname}/a")])
	end

	it "lists dirs" do
		system "mkdir -p #{@dir.full_path}/b"
		expect(@dir.dirs).to eq([Rush::Dir.new("#{@dirname}/b")])
	end

	it "lists combined files and dirs" do
		@dir['c'].create
		@dir['d/'].create
		expect(@dir.contents.size).to eq 2
	end

	it "fetches the entry_tree of all contents recursively" do
		@dir['a/'].create['b/'].create['c'].create
		expect(@dir.entries_tree).to eq @dir.make_entries(%w(a/ a/b/ a/b/c))
	end

	it "maps [] to find_by_name" do
		expect(@dir).to receive(:find_by_name).once
		@dir['one']
	end

	it "maps [] with a wildcard character to find_by_glob" do
		expect(@dir).to receive(:find_by_glob).once
		@dir['*']
	end

	it "can use symbols or strings for [] access" do
		expect(@dir).to receive(:find_by_name).once.with('subdir')
		@dir[:subdir]
	end

	it "[] can return a file that has yet to be created" do
		expect(@dir['not_yet']).to be_kind_of Rush::File
	end

	it "makes a list of entries from an array of filenames" do
		@dir['a'].create
		@dir['b/c/'].create
		expect(@dir.make_entries(%w(a b/c))).to eq([ @dir['a'], @dir['b/c'] ])
	end

	it "lists flattened files from all nested subdirectories" do
		@dir['1'].create
		@dir['2/3/'].create['4'].create
		@dir['a/b/c/'].create['d'].create
		expect(@dir.files_flattened).to eq @dir.make_entries(%w(1 2/3/4 a/b/c/d))
	end

	it "lists flattened dirs from all nested subdirectories" do
		@dir.create_dir('1/2')
		expect(@dir.dirs_flattened).to eq @dir.make_entries(%w(1/ 1/2/))
	end

	it "** as a shortcut to flattened_files" do
		expect(@dir['**']).to eq @dir.files_flattened
	end

	it "**/ as a shortcut to flattened_files + regular globbing" do
		@dir.create_file('1.rb')
		@dir.create_file('ignore.txt')
		@dir.create_dir('2').create_file('3.rb')
		@dir.create_dir('a/b').create_file('c.rb')
		expect(@dir['**/*.rb']).to eq @dir.make_entries(%w(1.rb 2/3.rb a/b/c.rb))
	end

	it "lists nonhidden files" do
		@dir.create_file('show')
		@dir.create_file('.dont_show')
		expect(@dir.nonhidden_files).to eq @dir.make_entries(%(show))
	end

	it "lists nonhidden dirs" do
		@dir.create_dir('show')
		@dir.create_dir('.dont_show')
		expect(@dir.nonhidden_dirs).to eq @dir.make_entries(%(show/))
	end

  it "knows its size in bytes, which includes its contents recursively" do
    @dir.create_file('a').write('1234')
    # on OSX fs stat's size is 102, even though blksize=4096
    # on Linux size is 4096
    expect(@dir.size).to eq(::File.stat(@dir.path).size + 4)
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
		expect(@dir.bash("cat file")).to eq "test\n"
	end

	it "can run bash within directories with spaces" do
		@dir.create_dir('with space').create_file('file').write('test')
		expect(@dir["with space/"].bash("cat file")).to eq "test"
	end

	it "passes bash options (e.g., :user) through to the box bash command" do
		expect(@dir).to receive(:bash).with('cmd', :opt1 => 1, :opt2 => 2)
		@dir.bash('cmd', :opt1 => 1, :opt2 => 2)
	end
end
