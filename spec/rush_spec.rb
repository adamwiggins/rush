require_relative 'base'

describe Rush do
  it 'fetches a local file path' do
    expect(Rush['/etc/hosts'].full_path).to eq('/etc/hosts')
  end

  it 'fetches the dir of __FILE__' do
    expect(Rush.dir(__FILE__).name).to eq('spec')
  end

  it 'fetches the launch dir (aka current working directory or pwd)' do
    allow(Dir).to receive(:pwd).and_return('/tmp')
    expect(Rush.launch_dir).to eq(Rush::Box.new['/tmp/'])
  end

  it 'runs a bash command' do
    expect(Rush.bash('echo hi')).to eq("hi\n")
  end

  it 'gets the list of local processes' do
    expect(Rush.processes).to be_kind_of(Rush::ProcessSet)
  end

  it 'gets my process' do
    expect(Rush.my_process.pid).to eq(Process.pid)
  end
end
