require_relative 'base'

describe Rush::Box do
  before do
    @sandbox_dir = "/tmp/rush_spec.#{Process.pid}"
    system "rm -rf #{@sandbox_dir}; mkdir -p #{@sandbox_dir}"

    @box = Rush::Box.new('localhost')
  end

  after do
    system "rm -rf #{@sandbox_dir}"
  end

  it "looks up entries with [] syntax" do
    expect(@box['/']).to eq Rush::Dir.new('/', @box)
  end

  it "looks up processes" do
    expect(@box.connection).to receive(:processes).and_return([{ :pid => 123 }])
    expect(@box.processes).to eq [Rush::Process.new({ :pid => 123 }, @box)]
  end

  it "executes bash commands" do
    expect(@box.connection).to receive(:bash).with('cmd', nil, false, false).and_return('output')
    expect(@box.bash('cmd')).to eq 'output'
  end

  it "executes bash commands with an optional user" do
    expect(@box.connection).to receive(:bash).with('cmd', 'user', false, false)
    @box.bash('cmd', :user => 'user')
  end

  it "executes bash commands in the background, returning a Rush::Process" do
    expect(@box.connection).to receive(:bash).with('cmd', nil, true, false).and_return(123)
    allow(@box).to receive(:processes).and_return([double('ps', :pid => 123)])
    expect(@box.bash('cmd', :background => true).pid).to eq 123
  end

  it "builds a script of environment variables to prefix the bash command" do
    expect(@box.command_with_environment('cmd', { :a => 'b' })).to eq "export a=\"b\"\ncmd"
  end

  it "escapes quotes on environment variables" do
    expect(@box.command_with_environment('cmd', { :a => 'a"b' })).to eq "export a=\"a\\\"b\"\ncmd"
  end

  it "escapes backticks on environment variables" do
    expect(@box.command_with_environment('cmd', { :a => 'a`b' })).to eq "export a=\"a\\\`b\"\ncmd"
  end

  it "converts environment variables to_s" do
    expect(@box.command_with_environment('cmd', { :a => nil, :b => 123 })).to eq "export a=\"\"\nexport b=\"123\"\ncmd"
  end

  it "sets the environment variables from the provided hash" do
    allow(@box.connection).to receive(:bash)
    expect(@box).to receive(:command_with_environment).with('cmd', { 1 => 2 })
    @box.bash('cmd', :env => { 1 => 2 })
  end

  it "checks the connection to determine if it is alive" do
    expect(@box.connection).to receive(:alive?).and_return(true)
    expect(@box).to be_alive
  end

  it "establish_connection to set up the connection manually" do
    expect(@box.connection).to receive(:ensure_tunnel)
    @box.establish_connection
  end

  it "establish_connection can take a hash of options" do
    expect(@box.connection).to receive(:ensure_tunnel).with(:timeout => :infinite)
    @box.establish_connection(:timeout => :infinite)
  end
end
