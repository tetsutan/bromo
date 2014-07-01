
require 'logger'

require 'bromo/config'
require 'bromo/server'
require 'bromo/manager'
require 'bromo/recorder'

module Bromo

  class Logger

    def self.debug(message)
      @@logger ||= ::Logger.new(STDOUT).tap do |l|
        l.level = ::Logger::DEBUG
      end
      @@logger.debug(message)
    end

  end

end

