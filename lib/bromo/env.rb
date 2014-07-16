module Bromo

  class Env

    def self.development?
      env = ENV['RACK_ENV']
      !env || env == 'development'
    end

  end

end
