require 'gtk2'

module Cleopatra

  # A window that can display and send information to the
  # GTK GUI of Vim (gVim)
  class VimWindow

    # Create the VimWindow. You must call start after this window is visible
    def initialize
      # A unique Vim server name
      @vim_server_name = "Cleopatra_#{Process.pid}"
      @gtk_socket = Gtk::Socket.new
      @gtk_socket.show_all
      @gtk_socket.signal_connect("delete_event") do
        false
      end
      @gtk_socket.signal_connect("destroy") do
        Gtk.main_quit
      end
      @gtk_socket.can_focus = true
      @gtk_socket.has_focus = true
      @vim_started = false
    end

    # The "window" for this object
    def gtk_window
      @gtk_socket
    end
    
    # Open the specified file in Vim
    def open(path, kind = :open)
      start
      path = path.gsub "'", "\\'"
      case kind
      when :open, :split_open
        if kind == :split_open
          `gvim --servername #{@vim_server_name} --remote-send '<ESC><ESC><ESC>:split<CR>'`
        end
        `gvim --servername #{@vim_server_name} --remote '#{path}'`
      when :tab_open
        `gvim --servername #{@vim_server_name} --remote-tab '#{path}'`
      else
        raise "Unknow open kind: #{kind}"
      end
      `gvim --servername #{@vim_server_name} --remote-send '<ESC><ESC><ESC>:buffer #{path}<CR>'`
      focus_vim
      self
    end

    # Start Vim's window. This must be called after the window which
    # will contain Vim is visible.
    def start
      return if @vim_started
      @vim_started = true
      fork do
        `gvim --socketid #{@gtk_socket.id} --servername #{@vim_server_name} --cmd "set guioptions-=T" --cmd "set guioptions-=m"`
      end
      self
    end

    # Set the focus to Vim
    def focus_vim
      @gtk_socket.can_focus = true
      @gtk_socket.has_focus = true
    end
  end
end
