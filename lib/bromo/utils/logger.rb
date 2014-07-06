require 'logger'
require 'active_support/concern'

module Bromo
  module Utils
    module Logger

      extend ActiveSupport::Concern

      included do
        extend ClassMethods
      end

      module ClassMethods
        def logger
          Logger.logger
        end
      end

      def self.logger
        @@logger ||= ::Logger.new(STDOUT).tap do |l|
          l.level = ::Logger::DEBUG if Env.development?
        end
      end

      def logger
        self.class.logger
      end

    end
  end
end

