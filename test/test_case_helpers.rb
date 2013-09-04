require_relative "test_case"

# All helper test cases should inherit from this class.
# Use the method 'helper' to access methods in the helper being tested.
#
#   IMPORTANT: Test classes for helpers must be names "TestHelperModule" where "HelperModule"
#   matches the name of the helper module exactly (including case).
# Use 'rake test' from the command line to run tests.
# See http://www.sinatrarb.com/testing.html for testing information

class TestCaseHelpers < TestCase
  include Sinatra::Helpers::ApplicationHelper
  Sinatra::Helpers.constants.each do |helper|
    helper = Sinatra::Helpers.const_get(helper)
    include helper if helper.class == Module
  end

  def helper
    class_name = self.class.name.gsub(/^Test/, "")
    helper_class = Kernel.const_get("Sinatra").const_get("Helpers").const_get(class_name)
    extend helper_class
  end
end