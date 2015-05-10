require_relative 'base'
require_relative '../lib/rush/path'

describe Rush::Path do
  it 'works' do
    expect(Rush::Path.executables).to be_kind_of Array
  end

  it "doesn't fail with non-existent directories in PATH" do
    expect(ENV).to receive(:[]).with("PATH").and_return("/foobar")
    expect(Rush::Path.executables).to eq []
  end
end
