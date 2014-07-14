module Helpers

  def cheat_bromo_core

    data_dir = File.join(File.dirname(__FILE__), 'data')
    ENV['BROMO_CONFIG_PATH'] = File.join(data_dir, 'bromorc.rb')
    Bromo::Config.data_dir = data_dir

    Bromo::Core.core.running = true
  end

end
