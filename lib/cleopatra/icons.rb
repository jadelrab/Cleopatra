require 'cleopatra/nice_singleton'

module Cleopatra

  # Manages the icons that can be loaded from the disk
  class Icons
    include NiceSingleton
    
    # The filenames for the icons of the windows
    WINDOW_ICON_FILENAME = 'assets/window_icon/cleo%d.png'.freeze
    # The size for the icons of the windows
    WINDOW_ICON_SIZES = [16, 32, 48].freeze

    # Create the Icons class. Cannot be called directly
    def initialize
      @gtk_window_icons = []
    end
    
    # Get an array of icons for the windows
    def window_icons
      # Load them
      load_window_icons
      @gtk_window_icons.freeze
      # Once loaded, we only need a reader
      self.class.send(:define_method, :window_icons) do
        @gtk_window_icons
      end
      # Return the value
      window_icons
    end

    private

    # Load the icons for the windows
    def load_window_icons
      WINDOW_ICON_SIZES.each do |size|
        file = File.join($lib_dir, WINDOW_ICON_FILENAME % [size])
        begin
          @gtk_window_icons << Gdk::Pixbuf.new(file) if File.exist? file
        rescue StandardError => e
          puts e.to_s
          puts "Problem loading window icon #{file}"
        end
      end
    end

  end
end
