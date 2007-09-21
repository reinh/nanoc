require 'test/unit'

require File.dirname(__FILE__) + '/test_helper.rb'

class CompilerTest < Test::Unit::TestCase
  def setup
    $quiet = true unless ENV['QUIET'] == 'false'
    FileManager.create_dir 'tmp'
  end

  def teardown
    FileUtils.remove_entry_secure 'tmp'
    Dir['test/fixtures/*/output/*'].each { |f| FileUtils.remove_entry_secure f }
    $quiet = false
  end

  def test_compile_empty_site
    with_fixture 'empty_site' do
      assert_nothing_raised() { $nanoc_compiler.run }

      assert_equal(1, Dir["output/*"].size)
      assert(File.file?('output/index.html'))
      assert(!File.file?('output/moo/index.html'))
    end
  end

  def test_compile_site_with_one_page
    with_fixture 'site_with_one_page' do
      assert_nothing_raised() { $nanoc_compiler.run }

      assert_equal(2, Dir["output/*"].size)
      assert(File.file?('output/index.html'))
      assert(File.file?('output/moo/index.html'))
    end
  end

  def test_compile_site_with_nested_layouts
    with_fixture 'site_with_nested_layouts' do
      assert_nothing_raised() { $nanoc_compiler.run }

      assert_equal(1, Dir["output/*"].size)
      assert(File.file?('output/index.html'))
      assert_match(/This is the default layout/, File.read('output/index.html'))
      assert_match(/This is the page layout/, File.read('output/index.html'))
    end
  end

  def test_compile_site_with_custom_paths
    with_fixture 'site_with_custom_paths' do
      assert_nothing_raised() { $nanoc_compiler.run }

      assert_equal(2, Dir["output/*"].size)
      assert(File.file?('output/index.html'))
      assert(File.file?('output/bar.html'))
      assert(!File.file?('output/foo/index.html'))
      assert(!File.file?('output/bar/index.html'))
    end
  end

  def test_compile_site_with_custom_extensions
    with_fixture 'site_with_custom_extensions' do
      assert_nothing_raised() { $nanoc_compiler.run }

      assert_equal(1, Dir["output/*"].size)
      assert(!File.file?('output/index.html'))
      assert(File.file?('output/index.xhtml'))
    end
  end

  def test_compile_site_with_custom_output_dir
    with_fixture 'site_with_custom_output_dir' do
      assert_nothing_raised() { $nanoc_compiler.run }

      assert_equal(0, Dir["output/*"].size)
      assert(!File.file?('output/index.html'))

      assert_equal(1, Dir["tmp/custom_output/*"].size)
      assert(File.file?('tmp/custom_output/index.html'))

      FileUtils.remove_entry_secure 'tmp'
    end
  end

  def test_compile_site_with_cool_content_file_names
    with_fixture 'site_with_cool_content_file_names' do
      assert_nothing_raised() { $nanoc_compiler.run }

      assert_equal(2, Dir["output/*"].size)
      assert(File.file?('output/index.html'))
      assert(File.file?('output/about/index.html'))
    end
  end

  def test_compile_site_with_draft_pages
    with_fixture 'site_with_draft_pages' do
      assert_nothing_raised() { $nanoc_compiler.run }

      assert_equal(1, Dir["output/*"].size)
      assert(File.file?('output/index.html'))
      assert(!File.file?('output/about/index.html'))
    end
  end

  def test_compile_site_with_backup_files
    with_fixture 'site_with_backup_files' do
      assert_nothing_raised() { $nanoc_compiler.run }
    end
  end

  def test_compile_site_with_double_extensions
    with_fixture 'site_with_double_extensions' do
      assert_nothing_raised() { $nanoc_compiler.run }
      assert(File.file?('output/index.html'))
      assert_equal(1, Dir["output/*"].size)
    end
  end

  def test_compile_site_with_no_layout
    with_fixture 'site_with_no_layout' do
      assert_nothing_raised() { $nanoc_compiler.run }
      assert(File.file?('output/index.html'))
      assert_equal(1, Dir["output/*"].size)
      assert_match(/This is a page without layout/, File.read('output/index.html'))
    end
  end

  def test_compile_site_with_markaby_layout
    foo = Markaby::Builder.new
    with_fixture 'site_with_markaby_layout' do
      assert_nothing_raised() { $nanoc_compiler.run }
      assert(File.file?('output/index.html'))
      assert_equal(1, Dir["output/*"].size)
      assert_match(/<html><head>/, File.read('output/index.html'))
    end
  rescue NameError
    $stderr.puts 'WARNING: test_compile_site_with_markaby_layout failed (Markaby not installed?)'
  end

  def test_compile_site_with_liquid_layout
    foo = Liquid::Template.new
    with_fixture 'site_with_liquid_layout' do
      assert_nothing_raised() { $nanoc_compiler.run }
      assert(File.file?('output/index.html'))
      assert_equal(1, Dir["output/*"].size)
      assert_match(/<p>This is a Liquid-powered site.<\/p>/, File.read('output/index.html'))
    end
  rescue NameError
    $stderr.puts 'WARNING: test_compile_site_with_liquid_layout failed (Liquid not installed?)'
  end

  def test_compile_site_with_haml_layout
    foo = Haml::Engine.new('...')
    with_fixture 'site_with_haml_layout' do
      assert_nothing_raised() { $nanoc_compiler.run }
      assert(File.file?('output/index.html'))
      assert_equal(1, Dir["output/*"].size)
      assert_match(/<html>\n  <head>\n    <title>My New Homepage<\/title>/, File.read('output/index.html'))
      assert_match(/<p strange=\*attrs\*>heh<\/p>/, File.read('output/index.html'))
    end
  rescue NameError
    $stderr.puts 'WARNING: test_compile_site_with_haml_layout failed (Haml not installed?)'
  end

  def test_compile_site_with_page_dot_notation
    with_fixture 'site_with_page_dot_notation' do
      assert_nothing_raised() { $nanoc_compiler.run }
      assert(File.file?('output/index.html'))
      assert_equal(1, Dir["output/*"].size)
      assert_match(/<title>Foobar<\/title>/, File.read('output/index.html'))
      assert_match(/This page is called "Foobar"/, File.read('output/index.html'))
      assert_match(/ya rly/, File.read('output/index.html'))
      assert_match(/This page rocks./, File.read('output/index.html'))
    end
  end

  def test_compile_site_with_page_id_links
    with_fixture 'site_with_page_id_links' do
      assert_nothing_raised() { $nanoc_compiler.run }
      assert(File.file?('output/index.html'))
      assert(File.file?('output/about/index.html'))
      assert(File.file?('output/blog/index.html'))
      assert_equal(3, Dir["output/*"].size)
      assert_match(/<a href="\/">home page<\/a>/, File.read('output/about/index.html'))
      assert_match(/<a href="\/blog\/">blog<\/a>/, File.read('output/about/index.html'))
    end
  end

  def test_compile_site_with_non_outputed_pages
    with_fixture 'site_with_non_outputed_pages' do
      assert_nothing_raised() { $nanoc_compiler.run }
      assert(File.file?('output/index.html'))
      assert(!File.file?('output/hidden/index.html'))
      assert_equal(1, Dir["output/*"].size)
    end
  end

  def test_compile_site_with_custom_filename
    with_fixture 'site_with_custom_filename' do
      assert_nothing_raised() { $nanoc_compiler.run }
      assert(File.file?('output/default.html'))
      assert_equal(1, Dir["output/*"].size)
    end
  end

  def test_compile_site_with_circular_dependencies
    with_fixture 'site_with_circular_dependencies' do
      assert_raise(SystemExit) { $nanoc_compiler.run }
    end
  end

  def test_compile_site_with_page_id_links
    with_fixture 'site_with_custom_filters' do
      assert_nothing_raised() { $nanoc_compiler.run }
      assert(File.file?('output/index.html'))
      assert_equal(1, Dir["output/*"].size)
      assert_match(/nanoc rocks/, File.read('output/index.html'))
    end
  end

  def test_compile_outside_site
    in_dir %w{ tmp } do
      assert_raise(SystemExit) { $nanoc_compiler.run }
    end
  end

  def test_compile_newly_created_site
    in_dir %w{ tmp } do
      $nanoc_creator.create_site('tmp_site')
      in_dir %w{ tmp_site } do
        assert_nothing_raised() { $nanoc_compiler.run }

        assert_equal(1, Dir["output/*"].size)
        assert(File.file?('output/index.html'))
      end
      FileUtils.remove_entry_secure 'tmp_site'
    end
  end
end
