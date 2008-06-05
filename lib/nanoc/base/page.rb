module Nanoc

  # A Nanoc::Page represents a page in a nanoc site. It has content and
  # attributes, as well as a path. It can also store the modification time to
  # speed up compilation.
  class Page

    # Default values for pages.
    DEFAULTS = {
      :custom_path  => nil,
      :extension    => 'html',
      :filename     => 'index',
      :filters_pre  => [],
      :filters_post => [],
      :layout       => 'default',
      :skip_output  => false
    }

    # The Nanoc::Site this page belongs to.
    attr_accessor :site

    # The parent page of this page. This can be nil even for non-root pages.
    attr_accessor :parent

    # The child pages of this page.
    attr_accessor :children

    # A hash containing this page's attributes.
    attr_accessor :attributes

    # This page's path.
    attr_reader   :path

    # The time when this page was last modified.
    attr_reader   :mtime

    # TODO document
    attr_reader   :reps

    # Creates a new page.
    #
    # +content+:: This page's unprocessed content.
    #
    # +attributes+:: A hash containing this page's attributes.
    #
    # +path+:: This page's path.
    #
    # +mtime+:: The time when this page was last modified.
    def initialize(content, attributes, path, mtime=nil)
      # Set primary attributes
      @attributes     = attributes.clean
      @content        = { :raw => content, :pre => content, :post => nil }
      @path           = path.cleaned_path
      @mtime          = mtime

      # Start disconnected
      @parent         = nil
      @children       = []

      # Not modified, not created by default
      @modified       = false
      @created        = false

      # Reset flags
      @filtered_pre   = false
      @laid_out       = false
      @filtered_post  = false
      @written        = false

      # Build reps
      build_page_reps
    end

    # Returns a proxy (Nanoc::PageProxy) for this page.
    def to_proxy
      @proxy ||= PageProxy.new(self)
    end

    # Returns true if the compiled page has been modified during the last
    # compilation session, false otherwise.
    def modified?
      @modified
    end

    # Returns true if the compiled page did not exist before and had to be
    # recreated, false otherwise.
    def created?
      @created
    end

    # Returns true if the source page is newer than the compiled page, false
    # otherwise. Also returns false if the page modification time isn't known.
    def outdated?
      # Outdated if compiled file doesn't exist
      return true if !File.file?(disk_path)

      # Outdated if we don't know
      return true if @mtime.nil?

      # Get compiled mtime
      compiled_mtime = File.stat(disk_path).mtime

      # Outdated if file too old
      return true if @mtime > compiled_mtime

      # Outdated if dependencies outdated
      return true if @site.layouts.any? { |l| l.mtime and l.mtime > compiled_mtime }
      return true if @site.page_defaults.mtime and @site.page_defaults.mtime > compiled_mtime
      return true if @site.code.mtime and @site.code.mtime > compiled_mtime

      return false
    end

    # Returns the attribute with the given name.
    def attribute_named(name)
      return @attributes[name] if @attributes.has_key?(name)
      return @site.page_defaults.attributes[name] if @site.page_defaults.attributes.has_key?(name)
      return DEFAULTS[name]
    end

    # Returns the page's content in the given stage (+:raw+, +:pre+, +:post+)
    def content(stage=:pre)
      compile(false) if stage == :pre  and !@filtered_pre
      compile(true)  if stage == :post and !@filtered_post
      @content[stage]
    end

    # Returns the page's layout.
    def layout
      # Check whether layout is present
      return nil if attribute_named(:layout).nil?

      # Find layout
      @layout ||= @site.layouts.find { |l| l.path == attribute_named(:layout).cleaned_path }
      raise Nanoc::Errors::UnknownLayoutError.new(attribute_named(:layout)) if @layout.nil?

      @layout
    end

    # Returns the path to the compiled page on the disk.
    def disk_path
      @disk_path ||= @site.router.disk_path_for(self)
    end

    # Returns the path to the compiled page as used in the web site itself.
    def web_path
      @web_path ||= @site.router.web_path_for(self)
    end

    # Saves the page in the database, creating it if it doesn't exist yet or
    # updating it if it already exists. Tells the site's data source to save
    # the page.
    def save
      @site.data_source.loading do
        @site.data_source.save_page(self)
      end
    end

    # Moves the page to a new path. Tells the site's data source to move the
    # page.
    def move_to(new_path)
      @site.data_source.loading do
        @site.data_source.move_page(self, new_path)
      end
    end

    # Deletes the page. Tells the site's data source to delete the page.
    def delete
      @site.data_source.loading do
        @site.data_source.delete_page(self)
      end
    end

    # Compiles the page.
    #
    # +also_layout+:: When +true+, will layout and post-filter the page, as
    #                 well as write out the compiled page. Otherwise, will
    #                 just pre-filter the page.
    def compile(also_layout=true)
      # Compile all representations
      @reps.values.each do |rep|
        rep.compile(also_layout)
      end
    end

  private

    # TODO document
    def build_page_reps
      @reps = {}

      # Build default rep
      default_rep_attrs = (@attributes[:reps] || {})[:default] || {}
      @reps[:default] = PageRep.new(self, default_rep_attrs, :default)

      # Build other reps
      (@attributes[:reps] || {}).each_pair do |name, attrs|
        @reps[name] = PageRep.new(self, attrs, name)
      end
    end

  end

end
