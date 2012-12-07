require_relative '../test_case_helpers'

class TestApplicationHelper < TestCaseHelpers
  def test_it_escapes_html
    escaped_html = helper.h("<a>http://testlink.com</a>")
    assert escaped_html.eql?("&lt;a&gt;http:&#x2F;&#x2F;testlink.com&lt;&#x2F;a&gt;")
  end
end