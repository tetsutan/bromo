require 'sinatra/base'
require 'rss'
require 'slim'


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

      def hostname
        return @hostname if @hostname

        host = Config.host || request.host
        port = Config.port || request.port
        if port && port != 80
          host = "#{host}:#{port}"
        end

        @hostname = host
        @hostname
      end

      def check_filepath(file_name, dir)
        name, ext = Utils.shell_filepathable(file_name).split(".")
        path = File.join(dir, "#{name}.#{ext}")

        path_base = File.dirname(File.expand_path(path))

        if path_base.start_with?(dir)
          return path
        else
          return nil
        end
      end

    end

    get '/list/*.xml' do |group_name|
      protected!

      group = Model::Group.find_by(name: group_name)
      return 404 if !group
      schedules = Model::Schedule.recorded_by_group(group)

      rss = RSS::Maker.make("2.0") do |maker|
        maker.channel.title = Config.podcast_title_prefix + group_name
        maker.channel.link = Config.podcast_link || Config.host || "www.example.com"
        maker.channel.description = maker.channel.title

        path = check_filepath(group.image_path, Config.image_dir)
        maker.channel.itunes_image = RSS::ITunesChannelModel::ITunesImage.new(path)

        maker.items.do_sort = true

        if !schedules.empty?
          maker.channel.lastBuildDate = Time.at(schedules.first.to_time)
        end

        schedules.each do |schedule|
          item = maker.items.new_item
          item.title = schedule.title
          item.description = schedule.description
          item.date = Time.at(schedule.from_time)

          # file_name = schedule.image_path
          # p item.itunes_image
          # p item.methods.select do |me|
          #   me.to_s.include?("itunes")
          # end

          # if file_name
          #   # item['itunes:image'] = "http://#{hostname}/data/image/#{file_name}"
          # end

          file_name = schedule.file_path
          if file_name
            file_path = File.join(Config.data_dir, file_name)

            item.enclosure.url = "http://#{hostname}/data/#{file_name}"
            item.enclosure.length = File.size(file_path)
            item.enclosure.type = "audio/mpeg"
          end
        end

      end

      rss.to_s
    end

    get '/data/*' do |file_name|
      protected!

      path = check_filepath(file_name, Config.data_dir)

      return unless path && File.file?(path)

      env['sinatra.static_file'] = path
      cache_control(*settings.static_cache_control) if settings.static_cache_control?
      send_file path, :disposition => nil
    end
    get '/image/*' do |file_name|
      protected!

      path = check_filepath(file_name, Config.image_dir)

      return unless path && File.file?(path)

      env['sinatra.static_file'] = path
      cache_control(*settings.static_cache_control) if settings.static_cache_control?
      send_file path, :disposition => nil
    end

    get '/status'do

      @schedule = {}
      @schedule[:recorded] = Model::Schedule.where(recorded: Model::Schedule::RECORDED_RECORDED).order("from_time DESC")
      @schedule[:recording] = Model::Schedule.where(recorded: Model::Schedule::RECORDED_RECORDING).order("from_time DESC")
      @schedule[:queue] = Model::Schedule.where(recorded: Model::Schedule::RECORDED_QUEUE).order("from_time DESC")
      @schedule[:failed] = Model::Schedule.where(recorded: Model::Schedule::RECORDED_FAILED).order("from_time DESC")

      @search_query = params[:q]

      @search_result = Model::Schedule.search(@search_query).order("from_time DESC")

      slim :status

    end

    get '/reload_rc' do
      QueueManager.clear_reservation
      Bromo::Config.reload_config
      Core.core.queue_manager.update_queue
    end


  end
end

