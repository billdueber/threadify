RSpec.describe "Threadify::Enumerator#each" do

  include_context "shared stuff" # in file spec/shared_stuff.rb

  it "runs all the items" do
    a = []
    te.each {|x| a << x}
    expect(a.size).to equal(enum.size)
  end

  it "doesn't preserve order" do
    a = []
    te.each {|x| sleep(wait_time) if x == slow_value; a << x}
    expect(a.size).to equal(enum.size)
    expect(a.last).to equal(slow_value)
  end

  it "returns the last value regardless of run order" do
    a    = []
    lval = te.each {|x| sleep(wait_time) if x == slow_value; a << x; x}
    expect(a.last).to be(slow_value)
    expect(lval).to be(last_value)
  end

end

