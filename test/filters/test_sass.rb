# encoding: utf-8

require 'test/helper'

class Nanoc3::Filters::SassTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_filter
    if_have 'sass' do
      # Get filter
      filter = ::Nanoc3::Filters::Sass.new({ :foo => 'bar' })

      # Run filter
      result = filter.run(".foo #bar\n  color: #f00")
      assert_match(/.foo\s+#bar\s*\{\s*color:\s+#f00;?\s*\}/, result)
    end
  end

  def test_filter_with_params
    if_have 'sass' do
      # Create filter
      filter = ::Nanoc3::Filters::Sass.new({ :foo => 'bar' })

      # Check with compact
      result = filter.run(".foo #bar\n  color: #f00", :style => 'compact')
      assert_match(/^\.foo #bar[\s\n]*\{[\s\n]*color:\s*#f00;?[\s\n]*\}/m, result)

      # Check with compressed
      result = filter.run(".foo #bar\n  color: #f00", :style => 'compressed')
      assert_match(/^\.foo #bar[\s\n]*\{[\s\n]*color:\s*#f00;?[\s\n]*\}/m, result)
    end
  end

  def test_filter_error
    if_have 'sass' do
      # Create filter
      filter = ::Nanoc3::Filters::Sass.new({ :foo => 'bar' })

      # Run filter
      raised = false
      begin
        filter.run('$*#&!@($')
      rescue Sass::SyntaxError => e
        assert_match '?', e.backtrace[0]
        raised = true
      end
      assert raised
    end
  end

end
