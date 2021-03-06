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
        ext = file_name.split(".").last
        name = file_name[0, file_name.size - ext.size - 1]
        path = File.join(dir, "#{Utils.shell_filepathable(name)}.#{ext}")
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

      if group_name == 'all'
        group = Model::Group.find_or_create_by(name: group_name)
        schedules = Model::Schedule.recorded.from_time_desc.limit(100)
      else
        group = Model::Group.find_by(name: group_name)
        return 404 if !group
        schedules = Model::Schedule.recorded_by_group(group).limit(50)
      end

      rss = RSS::Maker.make("2.0") do |maker|
        maker.channel.title = Config.podcast_title_prefix + group_name
        link = Config.podcast_link || Config.host || "www.example.com"
        if link
          maker.channel.link = URI.encode(link)
        end
        maker.channel.description = maker.channel.title

        if group.image_path
          path = check_filepath(group.image_path, Config.image_dir)
          if path
            maker.channel.itunes_image = URI.encode("http://#{hostname}/image/#{group.image_path}")
          end
        end

        maker.items.do_sort = true

        if !schedules.empty?
          maker.channel.lastBuildDate = Time.at(schedules.first.to_time)
        end

        maker.channel.itunes_subtitle = maker.channel.title


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

            item.enclosure.url = URI.encode("http://#{hostname}/data/#{file_name}")
            item.enclosure.length = File.size(file_path)
            item.enclosure.type = schedule.video? ? "video/mp4": "audio/mpeg"
          end
        end

      end

      rss.to_s
    end

    get '/data/*' do |file_name|
      protected! unless Config.remove_protection_when_sending_data

      Bromo.debug "Download request #{file_name}"

      path = check_filepath(file_name, Config.data_dir)

      return unless path && File.file?(path)

      env['sinatra.static_file'] = path
      cache_control(*settings.static_cache_control) if settings.static_cache_control?
      Bromo.debug "Download start #{file_name}"
      send_file path, :disposition => nil
    end
    get '/image/*' do |file_name|
      protected! unless Config.remove_protection_when_sending_data

      path = check_filepath(file_name, Config.image_dir)

      return unless path && File.file?(path)

      env['sinatra.static_file'] = path
      cache_control(*settings.static_cache_control) if settings.static_cache_control?
      send_file path, :disposition => nil
    end

    get '/status'do
      protected!

      @search_query = params[:q] || ""
      @search_result = nil
      if !@search_query.empty?
        one_week_ago = Time.now.to_i - 60 * 60 * 24 * 7
        @search_result = Model::Schedule.search(@search_query)
          .where("from_time > ?", one_week_ago)
          .from_time_desc
      end

      slim :status

    end

    get '/reload_rc' do
      protected!
      QueueManager.clear_reservation
      Bromo::Config.reload_config
      Core.core.queue_manager.update_queue
      Core.core.queue_exsleep.stop(true)
    end

    get '/redownload' do
      protected!

      id = params[:id]

      ActiveRecord::Base.connection_pool.with_connection do
        schedule = Model::Schedule.find(id)
        schedule.recorded = Model::Schedule::RECORDED_QUEUE
        schedule.save!
      end

      Core.core.queue_exsleep.stop(true)
    end

  end
end

