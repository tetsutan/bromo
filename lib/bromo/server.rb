require 'sinatra/base'
require 'rss'

module Bromo
  class Server < Sinatra::Base

    set :environment, :production
    set :traps, false
    set :run, false

    helpers do
      def protected!
        return unless Config.basic_authentication_env.all?
        unless authorized?
          response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
          throw(:halt, [401, "Not authorized\n"])
        end
      end

      def authorized?
        @auth ||=  Rack::Auth::Basic::Request.new(request.env)
        @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == Config.basic_authentication_env
      end
    end

    get '/list/*.xml' do |group_name|
      protected!

      schedules = Model::Schedule.recorded_by_group(group_name)

      rss = RSS::Maker.make("2.0") do |maker|
        maker.channel.title = Config.podcast_title_prefix + group_name
        maker.channel.link = Config.podcast_link || Config.host || "www.example.com"
        maker.channel.description = maker.channel.title
        maker.items.do_sort = true

        if !schedules.empty?
          maker.channel.lastBuildDate = Time.at(schedules.first.to_time)
        end

        schedules.each do |schedule|
          item = maker.items.new_item
          item.title = schedule.title
          item.description = schedule.description
          item.date = Time.at(schedule.from_time)

          file_name = schedule.file_path
          if file_name
            file_path = File.join(Config.data_dir, file_name)

            host = Config.host
            port = Config.port
            host = "#{host}:#{port}" if port

            item.enclosure.url = "http://#{host}/data/#{file_name}"
            item.enclosure.length = File.size(file_path)
            item.enclosure.type = "audio/mpeg"
          end
        end

      end

      rss.to_s
    end

    get '/data/*' do |file_name|
      protected!

      path = File.join(Config.data_dir, file_name)

      return unless File.file?(path)

      env['sinatra.static_file'] = path
      cache_control(*settings.static_cache_control) if settings.static_cache_control?
      send_file path, :disposition => nil
    end

    get '/status'do

      ret = []
      ret << "A::.connection_handler.connection_pool_list.map(&:connection) = "
      ret << ActiveRecord::Base.connection_handler.connection_pool_list.map(&:connection)
      ret << "A::.connection_handler.connection_pool_list.size = "
      ret << ActiveRecord::Base.connection_handler.connection_pool_list.size
      ret << "A::.connection_handler.connection_pool_list.first = "
      ret << ActiveRecord::Base.connection_handler.connection_pool_list.first
      ret.join("<br/>\n")
    end


  end
end

