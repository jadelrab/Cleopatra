#! /usr/bin/ruby1.8

#
# Cleopatra is a graphical add-on to Vim that was written and
# based on vimmate : God Bless It :)
#
module Cleopatra
end

# Find the lib directory based on the path of this file
$lib_dir = File.join(File.dirname(File.expand_path($0)), "/lib")
@cleopatra_lib_dir = File.join($lib_dir, "cleopatra")

# Add the lib directory in Ruby's search path
if File.directory? @cleopatra_lib_dir
  $:.unshift($lib_dir)
end

require 'rubygems'
require 'gtk2'

# We fork to give back the shell to the user, like Vim
fork do
  require 'cleopatra/main_window'
  require 'cleopatra/vim_window'
  require 'cleopatra/file_tree'

  if ARGV.empty?
    @initial_path = File.expand_path(".")
  else
    @initial_path = ARGV.first
  end

  # Create the main objects
  main = Cleopatra::MainWindow.new
  vim = Cleopatra::VimWindow.new
  ftree = Cleopatra::FileTree.new.rebuild_tree(self, @initial_path)
 
  main.vim_window = vim if vim

  ftree.add_open_signal do |path, kind|
    vim.open(path, kind)
  end

  # Add the viewport of the Treeview through a ScrolledWindow
  filesport = Gtk::ScrolledWindow.new.add(ftree)
  filesport.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)

  expander = Gtk::Expander.new('_Files', true)
  expander.add(filesport)

  expander.set_direction "ltr"

  expander.signal_connect("notify::expanded") {
    filesport.width_request=0
  }

  expander.expanded = false
  
  gtk_full_panel = Gtk::HPaned.new
  gtk_full_panel.pack1(expander, false, true)
  gtk_full_panel.add(vim.gtk_window)

  main.gtk_window.add(gtk_full_panel)

  # Go!
  main.start(vim)
end
