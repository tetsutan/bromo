require 'active_support'
require 'open-uri'
require 'nokogiri'
require 'swf_ruby'
require 'base64'
require 'streamio-ffmpeg'
require 'tempfile'
require 'pp'
require 'fileutils'
require 'cron_parser'

module Bromo
  module Media
    module Base

      module Setting
        module ClassMethods

          def media_name
            self.name.split("::").last.underscore
          end

          def realtime(val=nil)
            if val.nil?
              return self._realtime
            else
              self._realtime = !!val
            end
          end
          def recording_delay_for_realtime(val=nil)
            if val.nil?
              return self._recording_delay_for_realtime || 0
            else
              self._recording_delay_for_realtime = val
            end
          end
          def recording_extra_for_realtime(val=nil)
            if val.nil?
              return self._recording_extra_for_realtime || 0
            else
              self._recording_extra_for_realtime = val
            end
          end
          def refresh_time(val=nil)
            if val.nil?
              return self._refresh_time || "0 5 * * *"
            else
              self._refresh_time = val
            end
          end

          def term_of_nonrealtime(val=nil)
            if val.nil?
              return self._term_of_nonrealtime || (30 * 24 * 60 * 60) # default: 30 days
            else
              self._term_of_nonrealtime = val
            end
          end

          def realtime?
            self._realtime
          end

        end

      end


      extend ActiveSupport::Concern
      include Setting

      included do
        cattr_accessor :_realtime,
          :_recording_delay_for_realtime,
          :_recording_extra_for_realtime,
          :_refresh_time,
          :_term_of_nonrealtime
        extend ClassMethods
      end

      def name
        self.class.media_name
      end
      def realtime?
        self.class.realtime?
      end
      def recording_delay_for_realtime
        self.class.recording_delay_for_realtime
      end
      def recording_extra_for_realtime
        self.class.recording_extra_for_realtime
      end
      def refresh_time
        self.class.refresh_time
      end
      def term_of_nonrealtime
        self.class.term_of_nonrealtime
      end

      def next_update
        CronParser.new(refresh_time).next(Time.at(updated_at))
      end

      def updated_at
        information = Model::MediaInformation.find_or_create_by(media_name: name)
        information.schedule_updated_at.to_i || 0
      end


      def need_refresh?
        now = Time.now.to_i
        return next_update.to_i < now
      end

      def clear_before
        Model::Schedule.clear_before!(name)
      end

      def update_schedule
        if need_refresh?
          Bromo.debug "#{name} updating.."
          clear_before
          update_db
          information = Model::MediaInformation.find_by(media_name: name)
          information.schedule_updated_at = Time.now
          information.save
          return true
        end
        return false
      end

      # inheritance methods
      def update_db
        raise "do inherit update_db!"
      end
      def record(schedule)
        raise "do inherit record!"
      end

      # util
      def generate_filename(base_title, video = false)
        Time.now.strftime("%Y%m%d_%H%M_")+Utils.shell_filepathable(base_title)+
          (video ? ".mp4": ".mp3")
      end

      def transcode_to_mpx(src_path, dst_path)
        begin
          file = FFMPEG::Movie.new(src_path)
        rescue => e
          Bromo.debug e.message
          Bromo.debug "Cant open file #{src_path}"
          return
        end
        begin
          Bromo.debug "call transcode"
          file.transcode(dst_path)
        rescue
          Bromo.debug "transcode failed"
          FileUtils.copy(src_path, dst_path + ".err")
          return
        end
      end

      def save_tempfile_and_transcode_to_data_dir(data, file_name)
        # data set to tempfile
        tempfile = Tempfile::new('bromo_originl_data')
        tempfile.write data
        Bromo.debug "#{object_id} tempfile path = #{tempfile.path}"
        Bromo.debug "#{object_id} data size = #{data.size}"

        # transcord to mp3
        begin
          file = FFMPEG::Movie.new(tempfile.path)
          name = Utils.shell_filepathable(self.name)
        rescue => e
          Bromo.debug e.message
          Bromo.debug "Cant open tempfile #{tempfile.path}"
          return
        end

        delay_converting
        rec_filepath = File.join(Config.data_dir, file_name)
        file.transcode(rec_filepath)

        # remove old file
        tempfile.close(true)


      end

      def sleep_recording_delay(schedule)
        if realtime? && recording_delay_for_realtime > 0
          if schedule.to_time - Time.now.to_i > recording_delay_for_realtime
            sleep recording_delay_for_realtime
          end
        end
      end

      def delay_converting(count=0)
        return if count > 20
        return if !Bromo::Core.running?

        # realtime item that is recorded last
        last_recording = Model::Schedule.recording.now_on_air.to_time_desc.select { |schedule|
          if schedule.media
            schedule.media.realtime?
          else
            false
          end
        }.first

        if last_recording
          count+=1
          Bromo.debug "DelayConverting: wait for #{last_recording.title}"
          Bromo.exsleep(last_recording.end_time_to_left + rand(120..300)) # plus 2^5 min
          delay_converting(count)
        end

      end

    end
  end
end
