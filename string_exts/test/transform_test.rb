require 'test_helper'

class TransformTest < ActiveSupport::TestCase
  def test_initial
    assert_equal "a", "abc".initial
  end

  def test_first_three
    assert_equal "abc", "abcdef".first_three
  end

  def test_valid_xml_tag
    assert_equal "<valid_xml>", "< vAlid &$% xMl >".valid_xml_tag
  end



  def valid_xml_tag
    self.downcase.gsub(' ','_').gsub(/[^a-zA-Z0-9_.-]/, '')
  end

end