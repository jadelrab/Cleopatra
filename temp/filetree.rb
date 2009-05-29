#!/usr/bin/env ruby

require 'gtk2'

class FileTreeView < Gtk::TreeView

  def initialize
    @stocks = Hash[
      "file", [Gtk::Stock::FILE, "#000000"],
      "dir",  [Gtk::Stock::DIRECTORY, "#000000"]
      ]

    # Icon, Filename, FullPath
    @model = Gtk::TreeStore.new(Gdk::Pixbuf, String, String)
    super(@model)

    @gtk_filtered_tree_model = Gtk::TreeModelFilter.new(@model)

    # Double-click, Enter, Space: Signal to open the file
    self.signal_connect("row-activated") do |view, path, column|
      realpath = @gtk_filtered_tree_model.get_iter(path)[2]
      puts realpath
      ## TODO: set the open signal here
    end

    # Expanded row
    self.signal_connect("row-expanded") do |view, iter, path|
      realpath = @gtk_filtered_tree_model.get_iter(path)[2]
      ## TODO: set the update tree 
      
      #now we should get the parent iter  
      #then create the new real iter then populate it with the parent ;)
      #and then remove the dummy 

      to_remove_iter = Array.new
      @model.each do |m, p, i|
        if @model.ancestor?(iter, i)
          to_remove_iter << i
        end
      end

      dir_file_parse iter, realpath, false

      to_remove_iter.each do |x|
        @model.remove(x)
      end

    end

    pix = Gtk::CellRendererPixbuf.new
    text = Gtk::CellRendererText.new
    text.editable = false
    text.editable_set = false
    text.mode = Gtk::CellRenderer::MODE_EDITABLE
    text.signal_connect("edited") do |cell, path, str|
      @model.get_iter(path).set_value(1,  str)
    end

    @column = Gtk::TreeViewColumn.new

    @column.pack_start(pix, false)
    @column.set_cell_data_func(pix) do |column, cell, model, iter|
      cell.pixbuf = iter.get_value(0)
    end
    
    @column.pack_start(text, true)
    @column.set_cell_data_func(text) do |column, cell, model, iter|
      begin 
        Pango.parse_markup(iter.get_value(1))
        cell.markup = iter.get_value(1)
      rescue RuntimeError
        puts "--RuntimeError: Cell.markup {line:72}"
      end
    end

    @column.sort_column_id = 1
    append_column(@column)
    set_rules_hint(true)
    set_headers_visible(false)
  end

  def rebuild_tree(window)
    @parent_window = window
    begin 
      @model.freeze_notify
      create_tree
    rescue RuntimeError
      puts "--RuntimeError: timeout ? {line:88}"
    end
    self
  end

  def create_tree
    #dir_file_parse nil, "/pool/projects/Cleopatra/"
    dir_file_parse nil, "/"
  end

  def dir_file_parse(parent, path, recursive = false)
    s = Dir.entries(path).sort_by { |x|
      (File.directory? File.join(path, x)) ? 0 : 1
    }

    s.each do |file|
      file_path = File.join(path, file)
      if not file =~ /^\./ and File.readable? file_path
        ftype = (File.directory? file_path) ? "dir" : "file"
        iter = create_iter(parent, ftype, file, file_path)
      end
      if ftype == "dir" and not recursive
        dir_file_parse iter, file_path, true
      end
    end
  end

  def create_span(text, color)
    %Q[<span foreground="#{color}">#{text}</span>]
  end

  def create_iter(parent , stock, text, path)
    iter = @model.append(parent)
    iter.set_value(0, render_icon(@stocks[stock][0], Gtk::IconSize::MENU, text))
    iter.set_value(1, create_span(text, @stocks[stock][1]))
    iter.set_value(2, path)
  end

end

class FileTreeViewWindow < Gtk::Dialog
  def initialize
    super("Tree Viewer for Ruby/GTK", nil, 
          Gtk::Dialog::MODAL|Gtk::Dialog::NO_SEPARATOR,
          [Gtk::Stock::QUIT, 3])

    tv = FileTreeView.new.rebuild_tree(self)
  
    # Add the viewport of the Treeview through a ScrolledWindow
    filesport = Gtk::ScrolledWindow.new.add(tv)
    filesport.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
    vbox.add(filesport)

    signal_connect("response") do |widget, response|
      case response
        when 3
          destroy
          Gtk.main_quit
      end
    end
  
  end
end

Gtk.init
win = FileTreeViewWindow.new.set_default_size(500, 350).show_all
Gtk.main
