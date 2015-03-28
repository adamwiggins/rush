require_relative 'base'

describe Rush::ProcessSet do
  before do
    @process = double('process')
    @set = Rush::ProcessSet.new([ @process ])
  end

  it "is Enumerable" do
    expect(@set.select { |s| s == @process }).to eq [ @process ]
  end

  it "defines size" do
    expect(@set.size).to eq 1
  end

  it "defines first" do
    expect(@set.first).to eq @process
  end

  it "is equal to sets with the same contents" do
    expect(@set).to eq Rush::ProcessSet.new([ @process ])
  end

  it "is equal to arrays with the same contents" do
    expect(@set).to eq [ @process ]
  end

  it "kills all processes in the set" do
    expect(@process).to receive(:kill)
    @set.kill
  end

  it "checks the alive? state of all processes in the set" do
    expect(@process).to receive(:alive?).and_return(true)
    expect(@set.alive?).to eq [ true ]
  end

  it "filters the set from a conditions hash and returns the filtered set" do
    allow(@process).to receive(:pid).and_return(123)
    expect(@set.filter(:pid => 123).first).to eq @process
    expect(@set.filter(:pid => 456).size).to eq 0
  end

  it "filters with regexps if provided in the conditions" do
    allow(@process).to receive(:command).and_return('foobaz')
    expect(@set.filter(:command => /baz/).first).to eq @process
    expect(@set.filter(:command => /blerg/).size).to eq 0
  end
end
