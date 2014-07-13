require 'active_support'
require 'open-uri'
require 'nokogiri'
require 'swf_ruby'
require 'base64'
require 'streamio-ffmpeg'
require 'tempfile'
require 'pp'
require 'fileutils'

module Bromo
  module Media
    module Base

      module Setting
        module ClassMethods
          def realtime(val)
            self._realtime = !!val
          end
          def recording_delay_for_realtime(val)
            self._recording_delay_for_realtime = val
          end
        end

        def realtime?
          _realtime
        end
        def recording_delay_for_realtime
          _recording_delay_for_realtime
        end
      end


      extend ActiveSupport::Concern
      include Utils::Logger
      include Setting

      included do
        cattr_accessor :_realtime, :_recording_delay_for_realtime
        extend ClassMethods
      end

      def name
        self.class.name.split("::").last.downcase
      end

      def refresh_time_since
        Utils::Date.next("500")
      end

      def clear_before(key)
        case key
        when :two_weeks
          # TODO create method to clear old schedule on database
        end
      end

      def update_schedule
        clean_db
        update_db
      end

      # inheritance methods
      def clean_db
        raise "do inherit clean_db!"
      end
      def update_db
        raise "do inherit update_db!"
      end
      def record(*args)
        raise "do inherit record!"
      end

      # util
      def rec_filename
        @rec_filename ||= Time.now.strftime("%Y%m%d_%H%M_")+title+".mp3"
      end
      def rec_filepath
        @rec_filepath ||= File.join(Bromo::Cofnig.data_dir, rec_filename)
      end

      def transcode_to_mpx(src_path)
        begin
          file = FFMPEG::Movie.new(src_path)
          title = shell_filepathable(self.title)
        rescue => e
          Bromo.debug e.message
          Bromo.debug "Cant open file #{src_path}"
          return
        end
        begin
          Bromo.debug "call transcode"
          file.transcode(rec_filepath)
        rescue
          Radimo.debug "transcode failed"
          FileUtils.copy(src_path, rec_filepath + ".err")
          return
        end
      end

      def shell_filepathable(str)
        str.gsub(/[ \/\\\"\']/,'')
      end

      def sanitize(str)
        Nokogiri::HTML(str.to_s).text
      end

    end
  end
end
