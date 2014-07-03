module Bromo

  class Env

    def self.development?
      env = ENV['RAILS_ENV']
      !env || env == 'development'
    end

  end

end
