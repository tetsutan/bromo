require 'logger'

module Bromo
  module Utils
    module Logger

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

