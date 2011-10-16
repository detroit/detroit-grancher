require 'detroit/tool'

module Detroit

  # Convenicene method for creating a new Grancher tool instance.
  def Grancher(options={})
    Grancher.new(options)
  end

  # IMPORTANT! Grancher Tool is being deprecated in favor of the new GitHub
  # tool. Grancher has issues with Ruby 1.9 (due to encoding problems
  # in Gash library) and show no signs of being fixes.
  #
  # IMPORTANT! This toll only works with Ruby 1.8.x.
  #
  # This tool copies designated files to a git branch.
  # This is useful for dealing with situations like GitHub's
  # gh-pages branch for hosting project websites.[1]
  #
  # [1] A poor design copied from the Git project itself.
  class Grancher < Tool

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


    #  A S S E M B L Y  S T A T I O N S

    # Attach pre-publish method to pre-publish assembly station.
    def station_pre_publish
      transfer
    end

    # Attach publish method to publish assembly station.
    def station_publish
      publish
    end


    #  S E R V I C E  M E T H O D S

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

    # Same as transfer.
    alias_method :pre_publish, :transfer

    # Push files to remote.
    def publish
      require 'grancher'
      grancher.push
      report "Pushed site files to #{remote}."
    end

  private

    # TODO: Does the POM Project provide the site directory?
    def initialize_defaults
      @branch   ||= 'gh-pages'
      @remote   ||= 'origin'
      @sitemap  ||= default_sitemap
      #@keep_all ||= trial?
    end

    # Default sitemap includes the website directoy, if it exists.
    # Otherwise it looks for a `doc` or `docs` directory.
    #
    # NOTE: We have loop over the contents of the site directory
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

