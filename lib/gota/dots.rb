#!/usr/bin/env ruby

# frozen_string_literal: true

require 'pathname'
require 'find'

module Gota
  # Mirror Lar files in $HOME.
  class Dots
    attr_reader :root, :ignore_these, :utils, :home, :target_link

    def initialize(utils, root)
      @utils = utils
      @root = Pathname.new root if root
      @home = Pathname.new Dir.home
      @target_link = {}
    end

    def root_files_folders
      files = []
      folders = []

      Find.find(root) do |file|
        file = Pathname.new file
        next if file.to_path.include? '.git'
        next if file == root

        files << file if file.file?
        folders << file if file.directory?
      end

      { folders: folders, files: files }
    end

    # transform origin file absolute path with home as its root instead
    # /a/b/c.tar --> /home/b/c.tar
    def to_home(this)
      origin = this.to_path
      homey = home.to_path.concat('/')
      result = origin.gsub(root.to_path, homey)
      Pathname.new result
    end

    # Create only the folders, if those do not exist
    def make_folders
      root_files_folders[:folders].each do |fld|
        folder = to_home fld
        next if folder.exist?

        puts folder
        folder.mkdir
      end
    end

    def feed_target_link
      root_files_folders[:files].each do |target|
        next if ignored_ones.include? target.basename.to_s # TODO: .reject ignored_ones

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

    # ignore these ones
    def ignored_ones
      ['LICENSE', root.join('.git').to_path.to_s].freeze
    end

    def run
      feed_target_link
      make_folders
      backup_files
      symlink_files
    end
  end
end