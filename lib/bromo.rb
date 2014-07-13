
require 'bromo/utils'
require 'bromo/env'

require 'bromo/config'

require 'bromo/queue'
require 'bromo/server'
require 'bromo/queue_manager'
require 'bromo/schedule_updater'

require 'bromo/model'
require 'bromo/media'

require 'bromo/core'

# DB設定ファイルの読み込み
ActiveRecord::Base.configurations = YAML.load_file('config/database.yml')
ActiveRecord::Base.establish_connection(:development)

module Bromo
  def self.debug(str)
    Utils::Logger.logger.debug(str)
  end
end

