require 'gtk2'
require 'set'

module Cleopatra

  class FileTree < Gtk::TreeView

    def initialize
      @open_signal = Set.new

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
        path = @gtk_filtered_tree_model.get_iter(path)[2]
        @open_signal.each do |signal|
          signal.call(path, :tab_open)
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
          puts "Error ya pop"
        end
      end

      @column.sort_column_id = 1
      append_column(@column)
      set_rules_hint(true)
      set_headers_visible(false)
    end

    # Add a block that will be called when the user choose to open a file
    # The block take two argument: the path to the file to open, and a
    # symbol to indicate the kind: :open, :split_open, :tab_open
    def add_open_signal(&block)
      @open_signal << block
    end


    def rebuild_tree(window, path)
      @parent_window = window
      begin 
        @model.freeze_notify
        create_tree path
      rescue RuntimeError
        puts "Debug: --Rebuild Tree timeout ya pop"
      end
      self
    end

    def create_tree(path)
      dir_file_parse nil, path
    end

    def dir_file_parse(parent, path)
      
      if path.nil? 
        return
      end

      s = Dir.entries(path).sort_by { |x|
        (File.directory? File.join(path, x)) ? 0 : 1
      }

      s.each do |file|
        file_path = File.join(path, file)
        if not file =~ /^\./ and File.readable? file_path
          ftype = (File.directory? file_path) ? "dir" : "file"
          iter = create_iter(parent, ftype, file, file_path)
        end
        if ftype == "dir"
          dir_file_parse iter, file_path
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

end
