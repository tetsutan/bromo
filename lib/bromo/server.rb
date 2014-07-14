require 'sinatra/base'

module Bromo
  class Server < Sinatra::Base

    set :environment, :production
    set :bind, Config.host
    set :port, Config.port
    set :traps, false
    set :run, false

  end
end

