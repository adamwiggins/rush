require_relative 'base'

describe Array do
  it 'mixes commands into array' do
    expect([1, 2, 3].entries).to eq([1, 2, 3])
  end

  it 'can call head' do
    expect([1, 2, 3].head(1)).to eq([1])
  end

  it 'can call tail' do
    expect([1, 2, 3].tail(1)).to eq([3])
  end
end
