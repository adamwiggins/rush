require_relative 'base'

describe Rush::File do
  before do
    @sandbox_dir = "/tmp/rush_spec.#{Process.pid}"
    system "rm -rf #{@sandbox_dir}; mkdir -p #{@sandbox_dir}"

    @filename = "#{@sandbox_dir}/test_file"
    @contents = '1234'
    system "echo #{@contents} > #{@filename}"
    @contents += "\n"

    @file = Rush::File.new(@filename)
  end

  after do
    system "rm -rf #{@sandbox_dir}"
  end

  it 'is a child of Rush::Entry' do
    expect(@file).to be_kind_of(Rush::Entry)
  end

  it 'is not a dir' do
    expect(@file).to_not be_dir
  end

  it 'can create itself as a blank file, and return itself' do
    create_me = Rush::File.new("#{@sandbox_dir}/create_me")
    expect(create_me.create).to eq create_me
    expect(File.exist?("#{@sandbox_dir}/create_me")).to eq true
  end

  it 'can hardlink itself' do
    newdir = "#{@sandbox_dir}newdir"
    system "mkdir -p #{newdir}"

    dst  = newdir + "/link"
    link = @file.link(dst)

    expect(File.exist?(dst)).to eq true

    expect(link.full_path).to eq dst
  end

  it 'knows its size in bytes' do
    expect(@file.size).to eq @contents.length
  end

  it 'can read its contents' do
    expect(@file.contents).to eq @contents
  end

  it 'read is an alias for contents' do
    expect(@file.read).to eq @contents
  end

  it 'can write new contents' do
    @file.write('write test')
    expect(@file.contents).to eq 'write test'
  end

  it 'can count the number of lines it contains' do
    @file.write("1\n2\n3\n")
    expect(@file.line_count).to eq 3
  end

  it 'searches its contents for matching lines' do
    @file.write("a\n1\nb\n2\n")
    expect(@file.search(/\d/)).to eq %w(1 2)
  end

  it 'search returns nil if no lines match' do
    @file.write("a\nb\nc\n")
    expect(@file.search(/\d/)).to eq nil
  end

  it 'find-in-file replace' do
    @file.replace_contents!(/\d/, 'x')
    expect(@file.contents).to eq "xxxx\n"
  end

  it 'can destroy itself' do
    @file.destroy
    expect(::File.exist?(@filename)).to eq false
  end

  it "can fetch contents or blank if doesn't exist" do
    expect(Rush::File.new('/does/not/exist').contents_or_blank).to eq ''
  end

  it 'can fetch lines, or empty if doesn\'t exist' do
    expect(Rush::File.new('/does/not/exist').lines_or_empty).to eq []
  end
end
