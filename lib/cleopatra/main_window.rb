require 'gtk2'

module Cleopatra

  class MainWindow

    attr_accessor :vim_window

    #let's initialize 
    def initialize
      @gtk_main_window = Gtk::Window.new(Gtk::Window::TOPLEVEL)
      gtk_window.signal_connect("delete_event") do
        Gtk.main_quit
      end
      gtk_window.title = "Cleopatra Rocks"
      gtk_window.set_default_size(800, 600)
    end

    def gtk_window
      @gtk_main_window
    end

    def start(start_window)
      gtk_window.show_all
      start_window.start
      Gtk.main
    end

  end

end
