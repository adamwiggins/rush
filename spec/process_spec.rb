require_relative 'base'

describe Rush::Process do
  let!(:pid_file) { "/tmp/rush_rspec_#{Process.pid}" }

  before do
    @parent_pid = fork do
      # OSX includes checking `ps` process into current Process#children
      # as such isolate parent from the main thread
      # but the instance_valriabes are unavailable since #fork - use fs
      @pid = fork do
        sleep 999
      end
      ::File.write(pid_file, @pid)
      sleep 999
    end

    # wait parent to tell child's pid
    sleep 0.3

    @pid = ::File.read(pid_file).to_i
    @process = Rush::Process.all.detect { |p| p.pid == @pid }
  end

  after do
    ::File.unlink(pid_file) if ::File.exists?(pid_file)
    system "kill -9 #{@pid}"
    system "kill -9 #{@parent_pid}"
  end

  it 'knows all its child processes' do
    parent = Rush::Process.all.detect { |p| p.pid == @parent_pid }
    expect(parent.children).to eq [@process]
  end

  it 'gets the list of all processes' do
    list = Rush::Process.all
    expect(list.size).to be > 5
    expect(list.first).to be_kind_of Rush::Process
  end

  it 'knows the pid' do
    expect(@process.pid).to eq @pid
  end

  it 'knows the uid' do
    expect(@process.uid).to eq ::Process.uid
  end

  it 'knows the executed binary' do
    expect(@process.command).to match(/(ruby|rbx)/)
  end

  it 'knows the command line' do
    expect(@process.cmdline).to match(/rspec/)
  end

  it 'knows the memory used' do
    expect(@process.mem).to be > 0
  end

  it 'knows the cpu used' do
    expect(@process.cpu).to be >= 0
  end

  it 'knows the parent process pid' do
    expect(@process.parent_pid).to eq @parent_pid
  end

  it 'knows the parent process' do
    this = Rush::Box.new.processes
      .select { |p| p.pid == @parent_pid }
      .first
    expect(@process.parent).to eq this
  end

  it 'can kill itself' do
    process = Rush.bash('sleep 30', background: true)
    expect(process.alive?).to eq true
    process.kill
    sleep 0.1
    expect(process.alive?).to eq false
  end

  it 'if box and pid are the same, process is equal' do
    other = Rush::Process.new({ pid: @process.pid }, @process.box)
    expect(@process).to eq other
  end
end
