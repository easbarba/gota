#!/usr/bin/env ruby

# frozen_string_literal: true

require 'pathname'
require 'find'

module Gota
  # Mirror Lar files in $HOME.
  class Dots
    HOME = Pathname.new Dir.home

    attr_reader :root, :utils, :home, :target_link

    def initialize(services, root)
      @utils = services.resolve :utils

      @root = Pathname.new root if root
      @target_link = {}
    end

    # ignore these dotfiles
    def dotignored
      dots = root.join('.dotsignore').read.split "\n"
      dots.append '.dotsignore' # ignore it too, ofc!
      dots.uniq # users may not notice.
    end

    def children?(current)
      yep = false

      dotignored.each do |ignored|
        c = current.gsub "#{root.to_path}/", ''

        yep = true if c.start_with? ignored
      end

      yep
    end

    def files_folders
      files = []
      folders = []

      Find.find(root) do |current|
        next if current.include? '.git' # ignore the .git folder!
        next if children? current

        current = Pathname.new current
        next if current == root # ????

        files << current if current.file?
        folders << current if current.directory?
      end

      { folders: folders, files: files } # folders will not be a symlink
    end

    # transform origin file absolute path with home as its root instead
    # /a/b/c.tar --> /home/b/c.tar
    def to_home(this)
      origin = this.to_path
      homey = HOME.to_path.concat('/')
      result = origin.gsub(root.to_path, homey)

      Pathname.new result
    end

    # Create only the folders, if those do not exist
    def make_folders
      files_folders[:folders].each do |fld|
        folder = to_home fld
        next if folder.exist?

        puts folder
        folder.mkdir
      end
    end

    def files_mirrored
      raise 'not implemented'
    end

    def feed_target_link
      files_folders[:files].each do |target|
        next if dotignored.include? target.basename.to_s # TODO: .reject dotignored

        symlink_name = to_home target
        target_link.store(target, symlink_name)
      end
    end

    # Move file from home to a /home/backup/{file}
    # or delete it if the file it is pointing does not exist
    def backup_this(this)
      warn "WARNING: #{this} found! Deleting/Moving it."
      this.delete if this.exist? # TODO: if file exist back/delete up it
    end

    def backup_files
      target_link.each do |target, link_name|
        puts "#{target} ❯ #{link_name}"
        backup_this link_name
      end
    end

    def symlink_files
      target_link.each do |target, link_name|
        puts "#{target} ❯ #{link_name}"
        link_name.make_symlink target # As enumerator yielding folder to symlink
      end
    end

    def run
      feed_target_link
      make_folders
      backup_files
      symlink_files
    end
  end
end
