require 'singleton'

module Cleopatra
  module NiceSingleton

    def self.included(other)
      if other.class == Class
        other.send(:include, Singleton)
        class << other
          def method_missing(method, *args, &block)
            self.instance.send(method, *args)
          end
        end
      end
    end

  end
end

