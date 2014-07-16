
module Bromo
  module Recorder
    class Url
      attr_accessor :schedule
      def initialize(schedule)
        self.schedule = schedule
      end

      def record(url, file_name)

        begin
          open(url) do |f|
            rec_filepath = File.join(Config.data_dir, file_name)

            file = FFMPEG::Movie.new(f.path)
            file.transcode(rec_filepath)
          end
        rescue => e
          Bromo.debug e.message
          Bromo.debug "#{object_id} Can't open #{url} F#{__FILE__} L#{__LINE__}"
          block.call if block_given?
          return false
        end

        return file_name

      end


    end
  end
end

