require 'detroit-standard'

module Detroit

  ##
  # This tool copies designated files to a git branch. This is useful
  # for dealing with situations like GitHub's gh-pages branch for hosting
  # project websites (a poor design copied from the Git project itself).
  #
  # IMPORTANT! Grancher tool is being deprecated in favor of the new GitHub
  # tool. Grancher has issues with Ruby 1.9 (due to encoding problems
  # in Gash library) that show no signs of being fixed.
  #
  # The following stations of the standard toolchain are targeted:
  #
  # * :pre_publish
  # * :publish
  #
  # @note This tool may only works with Ruby 1.8.x.
  #
  class Grancher < Tool

    # Works with the Standard assembly.
    #
    # Attach `transfer` method to `pre_publish` assembly station, and
    # attach `publish` method to `publish` assembly station.
    #
    # @!parse
    #   include Standard
    #
    assembly Standard

    # Location of manpage for tool.
    MANPAGE = File.dirname(__FILE__) + '/../man/detroit-grancher.5'

    # Initialize defaults.
    #
    # @todo Does project provide the site directory?
    #
    # @return [void]
    def prerequisite
      @branch   ||= 'gh-pages'
      @remote   ||= 'origin'
      @sitemap  ||= default_sitemap
      #@keep_all ||= trial?
    end

    # The brach into which to save the files.
    attr_accessor :branch

    # The remote to use (defaults to 'origin').
    attr_accessor :remote

    # The repository loaiton (defaults to current project directory).
    #attr_accessor :repo

    # Commit message.
    #attr_accessor :message

    # List of any files/directories to not remove from the branch.
    attr_accessor :keep

    # Do not remove any files from the branh.
    attr_accessor :keep_all

    # List of directories and files to transfer.
    # If a single directory entry is given then the contents
    # of that directory will be transfered. Otherwise this 
    # can be an associative array or hash mapping seource to
    # destination.
    attr_reader :sitemap

    # Set sitemap.
    def sitemap=(entries)
      case entries
      when String, Symbol
        @sitemap = [entries]
      else
        @sitemap = entries
      end
    end

    # Cached Grancter instance.
    def grancher
      @grancher ||= ::Grancher.new do |g|
        g.branch  = branch
        g.push_to = remote

        #g.repo   = repo if repo  # defaults to '.'

        g.keep(*keep) if keep
        g.keep_all    if keep_all

        #g.message = (quiet? ? '' : 'Tranferred site files to #{branch}.')

        sitemap.each do |(src, dest)|
          trace "transfer: #{src} => #{dest}"
          dest = nil if dest == '.'
          if directory?(src)
            dest ? g.directory(src, dest) : g.directory(src)
          else
            dest ? g.file(src, dest)      : g.file(src)
          end
        end
      end
    end

    # Commit file to branch.
    def transfer
      sleep 1  # FIXME: had to pause so grancher will not bomb!
      require 'grancher'
      grancher.commit
      report "Tranferred site files to #{branch}."
    end

    # Push files to remote.
    def publish
      require 'grancher'
      grancher.push
      report "Pushed site files to #{remote}."
    end

    # This tool ties into the `pre_publish` and `publish` stations of the
    # standard assembly.
    #
    # @return [Boolean,Symbol]
    def assemble?(station, options={})
      return :transfer if station == :pre_publish
      return :publish  if station == :publish
      return false
    end

  private

    # Default sitemap includes the website directoy, if it exists.
    # Otherwise it looks for a `doc` or `docs` directory.
    #
    # @note This has to loop over the contents of the website directory
    # in order to pick up symlinks b/c Grancher doesn't support them.
    def default_sitemap
      sm  = []
      if dir = Dir['{site,web,website,www}'].first
        #sm << dir
        paths = Dir.entries(dir)
        paths.each do |path|
          next if path == '.' or path == '..'
          sm << [File.join(dir, path), path]
        end
      elsif dir = Dir["{doc,docs}"].first
        #sm << dir
        paths = Dir.entries(dir)
        paths.each do |path|
          next if path == '.' or path == '..'
          sm << [File.join(dir, path), path]
        end
      end
      sm
    end

  end

end

