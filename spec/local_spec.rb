require_relative 'base'

describe Rush::Connection::Local do
  before do
    @sandbox_dir = "/tmp/rush_spec.#{Process.pid}"
    system "rm -rf #{@sandbox_dir}; mkdir -p #{@sandbox_dir}"

    @con = Rush::Connection::Local.new
  end

  after do
    system "rm -rf #{@sandbox_dir}"
  end

  it "receive -> write_file(file, contents)" do
    expect(@con).to receive(:write_file).with('file', 'contents')
    @con.receive(:action => 'write_file', :full_path => 'file', :payload => 'contents')
  end

  it "receive -> append_to_file(file, contents)" do
    expect(@con).to receive(:append_to_file).with('file', 'contents')
    @con.receive(:action => 'append_to_file', :full_path => 'file', :payload => 'contents')
  end

  it "receive -> file_contents(file)" do
    expect(@con).to receive(:file_contents).with('file').and_return('the contents')
    expect(@con.receive(:action => 'file_contents', :full_path => 'file')).to eq 'the contents'
  end

  it "receive -> destroy(file or dir)" do
    expect(@con).to receive(:destroy).with('file')
    @con.receive(:action => 'destroy', :full_path => 'file')
  end

  it "receive -> purge(dir)" do
    expect(@con).to receive(:purge).with('dir')
    @con.receive(:action => 'purge', :full_path => 'dir')
  end

  it "receive -> create_dir(path)" do
    expect(@con).to receive(:create_dir).with('dir')
    @con.receive(:action => 'create_dir', :full_path => 'dir')
  end

  it "receive -> rename(path, name, new_name)" do
    expect(@con).to receive(:rename).with('path', 'name', 'new_name')
    @con.receive(:action => 'rename', :path => 'path', :name => 'name', :new_name => 'new_name')
  end

  it "receive -> copy(src, dst)" do
    expect(@con).to receive(:copy).with('src', 'dst')
    @con.receive(:action => 'copy', :src => 'src', :dst => 'dst')
  end

  it "receive -> read_archive(full_path)" do
    expect(@con).to receive(:read_archive).with('full_path').and_return('archive data')
    expect(@con.receive(:action => 'read_archive', :full_path => 'full_path')).to eq 'archive data'
  end

  it "receive -> write_archive(archive, dir)" do
    expect(@con).to receive(:write_archive).with('archive', 'dir')
    @con.receive(:action => 'write_archive', :dir => 'dir', :payload => 'archive')
  end

  it "receive -> index(base_path, glob)" do
    expect(@con).to receive(:index).with('base_path', '*').and_return(%w(1 2))
    expect(@con.receive(:action => 'index', :base_path => 'base_path', :glob => '*')).to eq "1\n2\n"
  end

  it "receive -> stat(full_path)" do
    expect(@con).to receive(:stat).with('full_path').and_return(1 => 2)
    expect(@con.receive(:action => 'stat', :full_path => 'full_path')).to eq YAML.dump(1 => 2)
  end

  it "receive -> set_access(full_path, user, group, permissions)" do
    access = double("access")
    expect(Rush::Access).to receive(:from_hash).with(:action => 'set_access', :full_path => 'full_path', :user => 'joe').and_return(access)

    expect(@con).to receive(:set_access).with('full_path', access)
    @con.receive(:action => 'set_access', :full_path => 'full_path', :user => 'joe')
  end

  it "receive -> size(full_path)" do
    expect(@con).to receive(:size).with('full_path').and_return("1024")
    expect(@con.receive(:action => 'size', :full_path => 'full_path')).to eq "1024"
  end

  it "receive -> chown(full_path, user, group, options)" do
    options = { noop: true }
    expect(@con).to receive(:chown).with('full_path', 'username', 'groupname', options )
    @con.receive(:action => 'chown', :full_path => 'full_path', user: 'username', group: 'groupname', options: options)
  end

  it "receive -> processes" do
    expect(@con).to receive(:processes).with(no_args).and_return([ { :pid => 1 } ])
    expect(@con.receive(:action => 'processes')).to eq YAML.dump([ { :pid => 1 } ])
  end

  it "receive -> process_alive" do
    expect(@con).to receive(:process_alive).with(123).and_return(true)
    expect(@con.receive(:action => 'process_alive', :pid => 123)).to eq '1'
  end

  it "receive -> kill_process" do
    expect(@con).to receive(:kill_process).with(123, :wait => 10).and_return(true)
    @con.receive(:action => 'kill_process', :pid => '123', :payload => YAML.dump(:wait => 10))
  end

  it "receive -> bash (reset environment)" do
    expect(@con).to receive(:bash).with('cmd', 'user', false, true).and_return('output')
    expect(@con.receive(:action => 'bash', :payload => 'cmd', :user => 'user', :background => 'false', :reset_environment => 'true')).to eq 'output'
  end

  it "receive -> bash (foreground)" do
    expect(@con).to receive(:bash).with('cmd', 'user', false, false).and_return('output')
    expect(@con.receive(:action => 'bash', :payload => 'cmd', :user => 'user', :background => 'false')).to eq 'output'
  end

  it "receive -> bash (background)" do
    expect(@con).to receive(:bash).with('cmd', 'user', true, false).and_return('output')
    expect(@con.receive(:action => 'bash', :payload => 'cmd', :user => 'user', :background => 'true')).to eq 'output'
  end

  it "receive -> unknown action exception" do
    expect { @con.receive(:action => 'does_not_exist') }.to raise_error(Rush::Connection::Local::UnknownAction)
  end

  it "write_file writes contents to a file" do
    fname = "#{@sandbox_dir}/a_file"
    data = "some data"
    @con.write_file(fname, data)
    expect(File.read(fname)).to eq data
  end

  it "append_to_file appends contents to a file" do
    fname = "#{@sandbox_dir}/a_file"
    system "echo line1 > #{fname}"
    @con.append_to_file(fname, 'line2')
    expect(File.read(fname)).to eq "line1\nline2"
  end

  it "file_contents reads a file's contents" do
    fname = "#{@sandbox_dir}/a_file"
    system "echo stuff > #{fname}"
    expect(@con.file_contents(fname)).to eq "stuff\n"
  end

  it "file_contents raises DoesNotExist if the file does not exist" do
    fname = "#{@sandbox_dir}/does_not_exist"
    expect { @con.file_contents(fname) }.to raise_error(Rush::DoesNotExist, fname)
  end

  it "destroy to destroy a file or dir" do
    fname = "#{@sandbox_dir}/delete_me"
    system "touch #{fname}"
    @con.destroy(fname)
    expect(File.exists?(fname)).to eq false
  end

  it "purge to purge a dir" do
    system "cd #{@sandbox_dir}; touch {1,2}; mkdir 3; touch 3/4"
    @con.purge(@sandbox_dir)
    expect(File.exists?(@sandbox_dir)).to eq true
    expect(Dir.glob("#{@sandbox_dir}/*")).to eq([])
  end

  it "purge kills hidden (dotfile) entries too" do
    system "cd #{@sandbox_dir}; touch .killme"
    @con.purge(@sandbox_dir)
    expect(File.exist?(@sandbox_dir)).to eq true
    expect(`cd #{@sandbox_dir}; ls -lA | grep -v total | wc -l`.to_i).to eq 0
  end

  it "create_dir creates a directory" do
    fname = "#{@sandbox_dir}/a/b/c/"
    @con.create_dir(fname)
    expect(File.directory?(fname)).to eq true
  end

  it "rename to rename entries within a dir" do
    system "touch #{@sandbox_dir}/a"
    @con.rename(@sandbox_dir, 'a', 'b')
    expect(File.exists?("#{@sandbox_dir}/a")).to eq false
    expect(File.exists?("#{@sandbox_dir}/b")).to eq true
  end

  it "copy to copy an entry to another dir on the same box" do
    system "mkdir #{@sandbox_dir}/subdir"
    system "touch #{@sandbox_dir}/a"
    @con.copy("#{@sandbox_dir}/a", "#{@sandbox_dir}/subdir")
    expect(File.exists?("#{@sandbox_dir}/a")).to eq true
    expect(File.exists?("#{@sandbox_dir}/subdir/a")).to eq true
  end

  it "copy raises DoesNotExist with source path if it doesn't exist or otherwise can't be accessed" do
    expect { @con.copy('/does/not/exist', '/tmp') }.to raise_error(Rush::DoesNotExist, '/does/not/exist')
  end

  it "copy raises DoesNotExist with destination path if it can't access the destination" do
    expect { @con.copy('/tmp', '/does/not/exist') }.to raise_error(Rush::DoesNotExist, '/does/not')
  end

  it "read_archive to pull an archive of a dir into a byte stream" do
    system "touch #{@sandbox_dir}/a"
    expect(@con.read_archive(@sandbox_dir).size).to be > 50
  end

  it "read_archive works for paths with spaces" do
    system "mkdir -p #{@sandbox_dir}/with\\ space; touch #{@sandbox_dir}/with\\ space/a"
    expect(@con.read_archive("#{@sandbox_dir}/with space").size).to be > 50
  end

  it "write_archive to turn a byte stream into a dir" do
    system "cd #{@sandbox_dir}; mkdir -p a; touch a/b; tar cf xfer.tar a; mkdir dst"
    archive = File.read("#{@sandbox_dir}/xfer.tar")
    @con.write_archive(archive, "#{@sandbox_dir}/dst")
    expect(File.directory?("#{@sandbox_dir}/dst/a")).to eq true
    expect(File.exist?("#{@sandbox_dir}/dst/a/b")).to eq true
  end

  it "write_archive works for paths with spaces" do
    system "cd #{@sandbox_dir}; mkdir -p a; touch a/b; tar cf xfer.tar a; mkdir with\\ space"
    archive = File.read("#{@sandbox_dir}/xfer.tar")
    @con.write_archive(archive, "#{@sandbox_dir}/with space")
    expect(File.directory?("#{@sandbox_dir}/with space/a")).to eq true
    expect(File.exists?("#{@sandbox_dir}/with space/a/b")).to eq true
  end

  it "index fetches list of all files and dirs in a dir when pattern is empty" do
    system "cd #{@sandbox_dir}; mkdir dir; touch file"
    expect(@con.index(@sandbox_dir, '')).to eq([ 'dir/', 'file' ])
  end

  it "index fetches only files with a certain extension with a flat pattern, *.rb" do
    system "cd #{@sandbox_dir}; touch a.rb; touch b.txt"
    expect(@con.index(@sandbox_dir, '*.rb')).to eq [ 'a.rb' ]
  end

  it "index raises DoesNotExist when the base path is invalid" do
    expect { @con.index('/does/not/exist', '*') }.to raise_error(Rush::DoesNotExist, '/does/not/exist')
  end

  it "stat gives file stats like size and timestamps" do
    expect(@con.stat(@sandbox_dir)).to have_key(:ctime)
    expect(@con.stat(@sandbox_dir)).to have_key(:size)
  end

  it "stat fetches the octal permissions" do
    expect(@con.stat(@sandbox_dir)[:mode]).to be_kind_of(Fixnum)
  end

  it "stat raises DoesNotExist if the entry does not exist" do
    fname = "#{@sandbox_dir}/does_not_exist"
    expect { @con.stat(fname) }.to raise_error(Rush::DoesNotExist, fname)
  end

  it "set_access invokes the access object" do
    access = double("access")
    expect(access).to receive(:apply).with('/some/path')
    @con.set_access('/some/path', access)
  end

  it "size gives size of a directory and all its contents recursively" do
    system "mkdir -p #{@sandbox_dir}/a/b/; echo 1234 > #{@sandbox_dir}/a/b/c"
    expect(@con.size(@sandbox_dir)).to eq (::File.stat(@sandbox_dir).size*3 + 5)
  end

  it "parses ps output on os x" do
    expect(@con.parse_ps("21712   501   21711   1236   0 /usr/bin/vi somefile.rb")).to eq({
      :pid => "21712",
      :uid => "501",
      :parent_pid => 21711,
      :mem => 1236,
      :cpu => 0,
      :command => '/usr/bin/vi',
      :cmdline => '/usr/bin/vi somefile.rb',
    })
  end

  it "gets the list of processes on os x via the ps command" do
    expect(@con).to receive(:os_x_raw_ps).and_return <<EOPS
PID UID   PPID  RSS  CPU COMMAND
1     0      1 1111   0 cmd1 args
2   501      1  222   1 cmd2
EOPS
    expect(@con.os_x_processes).to eq [
      { :pid => "1", :uid => "0", :parent_pid => 1, :mem => 1111, :cpu => 0, :command => "cmd1", :cmdline => "cmd1 args" },
      { :pid => "2", :uid => "501", :parent_pid => 1, :mem => 222, :cpu => 1, :command => "cmd2", :cmdline => "cmd2" },
    ]
  end

  it "the current process should be alive" do
    expect(@con.process_alive(Process.pid)).to eq true
  end

  it "a made-up process should not be alive" do
    expect(@con.process_alive(99999)).to eq false
  end

  it "kills a process by pid sending a TERM" do
    allow(@con).to receive(:process_alive).and_return(false)
    expect(::Process).to receive(:kill).with('TERM', 123).once
    @con.kill_process(123)
  end

  it "kills a process by pid sending a KILL signal if TERM doesn't work" do
    allow(@con).to receive(:process_alive).and_return(true)
    expect(::Process).to receive(:kill).with('TERM', 123).at_least(:twice)
    expect(::Process).to receive(:kill).with('KILL', 123)
    @con.kill_process(123)
  end

  it "kills a process by pid without sending TERM if :wait is zero" do
    expect(::Process).to_not receive(:kill).with('TERM', 123)
    expect(::Process).to receive(:kill).with('KILL', 123)
    @con.kill_process(123, :wait => 0)
  end

  it "does not raise an error if the process is already dead" do
    expect(::Process).to receive(:kill).and_raise(Errno::ESRCH)
    expect { @con.kill_process(123) }.to_not raise_error
  end

  it "executes a bash command, returning stdout when successful" do
    expect(@con.bash("echo test")).to eq "test\n"
  end

  it "executes a bash command, raising and error (with stderr as the message) when return value is nonzero" do
    expect { @con.bash("no_such_bin") }.to raise_error(Rush::BashFailed, /command not found/)
  end

  it "executes a bash command as another user using sudo" do
    expect(@con.bash("echo test2", ENV['USER'])).to eq "test2\n"
  end

  it "executes a bash command in the background, returning the pid" do
    expect(@con.bash("true", nil, true)).to be > 0
  end

  it "ensure_tunnel to match with remote connection" do
    @con.ensure_tunnel
  end

  it "always returns true on alive?" do
    expect(@con).to be_alive
  end

  it "resolves a unix uid to a user" do
    expect(@con.resolve_unix_uid_to_user(0)).to eq "root"
    expect(@con.resolve_unix_uid_to_user('0')).to eq "root"
  end

  it "returns nil if the unix uid does not exist" do
    expect(@con.resolve_unix_uid_to_user(9999)).to eq nil
  end

  it "iterates through a process list and resolves the unix uid for each" do
    list = [ { :uid => 0, :command => 'pureftpd' }, { :uid => 9999, :command => 'defunk' } ]
    expect(@con.resolve_unix_uids(list))
      .to eq([{ :uid => 0, :user => 'root', :command => 'pureftpd' },
              { :uid => 9999, :command => 'defunk', :user => nil }])
  end
end
