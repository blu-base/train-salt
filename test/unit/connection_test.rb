# Its job is to verify that the Connection class is setup correctly.

# Include our test harness
require_relative "../helper"

# Load the class under test, the Connection definition.
require "train-salt/connection"

# Because InSpec is a Spec-style test suite, we're going to use MiniTest::Spec
# here, for familiar look and feel. However, this isn't InSpec (or RSpec) code.
describe TrainPlugins::Salt::Connection do

  # When writing tests, you can use `let` to create variables that you
  # can reference easily.

  # This is a long name.  Shorten it for clarity.
  let(:connection_class) { TrainPlugins::Salt::Connection }

  # Some tests through here use minitest Expectations, which attach to all
  # Objects, and begin with 'must' (positive) or 'wont' (negative)
  # See https://ruby-doc.org/stdlib-2.1.0/libdoc/minitest/rdoc/MiniTest/Expectations.html

  it "should inherit from the Train Connection base" do
    # For Class, '<' means 'is a descendant of'
    _(connection_class < Train::Plugins::Transport::BaseConnection).must_equal(true)
  end

  # Since this is a Local-type connection, we MUST implement these three.
  %i{
    file_via_connection
    run_command_via_connection
  }.each do |method_name|
    it "should provide a #{method_name}() method" do
      # false passed to instance_methods says 'don't use inheritance'
      _(connection_class.instance_methods(false)).must_include(method_name)
    end
  end
end
