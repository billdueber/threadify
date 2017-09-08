require 'concurrent'
require 'threadify'

RSpec.configure do |rspec|
  rspec.shared_context_metadata_behavior = :apply_to_host_groups
end

RSpec.shared_context "shared stuff", :shared_context => :metadata do

  let(:enum) {5..15}
  let(:last_value) {15}
  let(:slow_value) {8}
  let(:wait_time) { 0.2 }
  let(:threads) { Concurrent.processor_count }
  let(:te) {Threadify::Enumerator.new(enum)}

end

RSpec.configure do |rspec|
  rspec.include_context "shared stuff", :include_shared => true
end
