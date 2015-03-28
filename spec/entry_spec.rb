require_relative 'base'

describe Rush::Entry do
  before do
    @sandbox_dir = "/tmp/rush_spec.#{Process.pid}/"
    system "rm -rf #{@sandbox_dir}; mkdir -p #{@sandbox_dir}"

    @filename = "#{@sandbox_dir}/test_file"
    system "touch #{@filename}"

    @entry = Rush::Entry.new(@filename)
  end

  after do
    system "rm -rf #{@sandbox_dir}"
  end

  it 'knows its name' do
    expect(@entry.name).to eq File.basename(@filename)
  end

  it 'knows its parent dir' do
    expect(@entry.parent).to be_kind_of(Rush::Dir)
    expect(@entry.parent.name).to eq File.basename(@sandbox_dir)
    expect(@entry.parent.full_path).to eq @sandbox_dir
  end

  it 'cleans its pathname' do
    expect(Rush::Entry.new('/a//b//c').full_path).to eq '/a/b/c'
    expect(Rush::Entry.new('/1/2/../3').full_path).to eq '/1/3'
  end

  it 'knows its changed_at time' do
    expect(@entry.changed_at).to eq File.stat(@filename).ctime
  end

  it 'knows its last_modified time' do
    expect(@entry.last_modified).to eq File.stat(@filename).mtime
  end

  it 'knows its last_accessed time' do
    expect(@entry.last_accessed).to eq File.stat(@filename).atime
  end

  it 'considers itself equal to other instances with the same full path' do
    expect(Rush::Entry.new('/not/the/same')).to_not eq @entry
    expect(Rush::Entry.new(@entry.full_path)).to eq @entry
  end

  it 'can rename itself' do
    new_file = 'test2'

    @entry.rename(new_file)

    expect(File.exist?(@filename)).to eq false
    expect(File.exist?("#{@sandbox_dir}/#{new_file}")).to eq true
  end

  it 'rename returns the renamed file' do
    expect(@entry.rename('file2')).to eq @entry.parent['file2']
  end

  it 'can\'t rename itself if another file already exists with that name' do
    new_file = 'test3'
    system "touch #{@sandbox_dir}/#{new_file}"

      expect { @entry.rename(new_file) }.to raise_error(Rush::NameAlreadyExists, /#{new_file}/)
  end

  it "can't rename itself to something with a slash in it" do
    expect { @entry.rename('has/slash') }.to raise_error(Rush::NameCannotContainSlash, /slash/)
  end

  it 'can duplicate itself within the directory' do
    expect(@entry.duplicate('newfile')).to eq Rush::File.new("#{@sandbox_dir}/newfile")
  end

  it 'can move itself to another dir' do
    newdir = "#{@sandbox_dir}/newdir"
    system "mkdir -p #{newdir}"

    dst = Rush::Dir.new(newdir)
    @entry.move_to(dst)

    expect(File.exist?(@filename)).to eq false
    expect(File.exist?("#{newdir}/#{@entry.name}")).to eq true
  end

  it 'can copy itself to another directory' do
    newdir = "#{@sandbox_dir}/newdir"
    system "mkdir -p #{newdir}"

    dst = Rush::Dir.new(newdir)
    @copied_dir = @entry.copy_to(dst)

    expect(File.exist?(@filename)).to eq true
    expect(File.exist?("#{newdir}/#{@entry.name}")).to eq true

      expect(@copied_dir.full_path).to eq "#{@sandbox_dir}newdir/#{@entry.name}"
  end

  it 'considers dotfiles to be hidden' do
    expect(Rush::Entry.new("#{@sandbox_dir}/show")).to_not be_hidden
    expect(Rush::Entry.new("#{@sandbox_dir}/.dont_show")).to be_hidden
  end

  it 'is considered equal to entries with the same full path and on the same box' do
    same = Rush::Entry.new(@entry.full_path, @entry.box)
    expect(@entry).to eq same
  end

  it 'is considered not equal to entries with the same full path on a different box' do
    same = Rush::Entry.new(@entry.full_path, Rush::Box.new('dummy'))
    expect(@entry).to_not eq same
  end

  it 'can mimic another entry' do
    copy = Rush::Entry.new('abc', :dummy)
    copy.mimic(@entry)
    expect(copy.path).to eq @entry.path
  end

  it 'can update the read access permission' do
    system "chmod 666 #{@filename}"
    @entry.access = { :user_can => :read }
    expect(`ls -l #{@filename}`).to match(/^-r--------/)
  end

  it 'reads the file permissions in the access hash' do
    system "chmod 640 #{@filename}"
    expect(@entry.access).to eq({ user_can_read: true, user_can_write: true, group_can_read: true })
  end
end
