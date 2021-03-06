# encoding: utf-8

module Nanoc3::DataSources

  # The filesystem_verbose data source is the old data source for a new nanoc
  # site. It stores all data as files on the hard disk.
  #
  # None of the methods are documented in this file. See {Nanoc3::DataSource}
  # for documentation on the overridden methods instead.
  #
  # The filesystem_verbose data source stores its items and layouts in nested
  # directories. Each directory represents a single item or layout. The root
  # directory for items is the `content` directory; for layouts it is the
  # `layouts` directory.
  #
  # Every directory has a content file and a meta file. The content file
  # contains the actual item content, while the meta file contains the item’s
  # or the layout’s metadata, formatted as YAML.
  #
  # Both content files and meta files are named after its parent directory
  # (i.e. item). For example, an item/layout named `foo` will have a directory
  # named `foo`, with e.g. a `foo.markdown` content file and a `foo.yaml` meta
  # file.
  #
  # Content file extensions are not used for determining the filter that
  # should be run; the meta file defines the list of filters. The meta file
  # extension must always be `.yaml`, though.
  #
  # For backwards compatibility, content files can also have the `index`
  # basename. Similarly, meta files can have the `meta` basename. For example,
  # a parent directory named `foo` can have an `index.txt` content file and a
  # `meta.yaml` meta file.
  #
  # The identifier is calculated by stripping the extension; if there is more
  # than one extension, only the last extension is stripped and the previous
  # extensions will be part of the identifier.
  class FilesystemVerbose < Nanoc3::DataSource

    include Nanoc3::DataSources::Filesystem

  private

    # See {Nanoc3::DataSources::Filesystem#create_object}.
    def create_object(dir_name, content, attributes, identifier, params={})
      # Determine base path
      last_component = identifier.split('/')[-1] || dir_name
      base_path = dir_name + identifier + last_component

      # Get filenames
      ext = params[:extension] || '.html'
      dir_path         = dir_name + identifier
      meta_filename    = dir_name + identifier + last_component + '.yaml'
      content_filename = dir_name + identifier + last_component + ext
                                     
      # Notify
      Nanoc3::NotificationCenter.post(:file_created, meta_filename)
      Nanoc3::NotificationCenter.post(:file_created, content_filename)

      # Create files
      FileUtils.mkdir_p(dir_path)
      File.open(meta_filename,    'w') { |io| io.write(YAML.dump(attributes.stringify_keys)) }
      File.open(content_filename, 'w') { |io| io.write(content) }
    end

    # See {Nanoc3::DataSources::Filesystem#filename_for}.
    def filename_for(base_filename, ext)
      last_part = base_filename.split('/')[-1]
      base_glob = base_filename.split('/')[0..-2].join('/') + "/{index,#{last_part}}."

      ext ? Dir[base_glob + ext][0] : nil
    end

    # See {Nanoc3::DataSources::Filesystem#identifier_for_filename}.
    def identifier_for_filename(filename)
      filename.sub(/[^\/]+\.yaml$/, '')
    end

  end

end
