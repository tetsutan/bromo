require 'logger'
require 'active_support/concern'

module Bromo
  module Utils
    module Logger

      extend ActiveSupport::Concern

      included do
        extend Logger
      end

      def logger
        @logger ||= ::Logger.new(STDOUT).tap do |l|
          l.level = ::Logger::DEBUG if Env.development?
        end
      end

    end
  end
end

