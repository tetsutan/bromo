module Helpers

  def cheat_bromo_core

    # Config
    data_dir = File.join(File.dirname(__FILE__), 'data')
    ENV['BROMO_CONFIG_PATH'] = File.join(data_dir, 'bromorc.rb')
    Bromo::Config.data_dir = data_dir

    # logger
    Bromo::Utils::Logger.logger.level = Logger::FATAL

    # running
    Bromo::Core.core.running = true
  end

end
