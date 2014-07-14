
require 'bromo/utils'
require 'bromo/env'

require 'bromo/config'

require 'bromo/queue'
require 'bromo/server'
require 'bromo/queue_manager'
require 'bromo/schedule_updater'
require 'bromo/recorder'

require 'bromo/model'
require 'bromo/media'

require 'bromo/core'

# DB設定ファイルの読み込み
ActiveRecord::Base.configurations = YAML.load_file('config/database.yml')
ActiveRecord::Base.establish_connection(:development)

module Bromo
  # wrappers
  def self.debug(str)
    Utils::Logger.logger.debug(str)
  end
  def self.debug?
    Config.debug
  end
  def self.exsleep(time)
    Utils::Exsleep.new.exsleep(time)
  end
end

