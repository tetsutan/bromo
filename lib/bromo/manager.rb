
module Bromo

  class Manager

    @@medias = nil
    def self.medias
      @@medias ||= Config.broadcaster_names.map {|name|

        class_name = name.capitalize
        klass = Bromo::Media.const_get(class_name)
        klass.new

      }
    end

    @@resevations = {}
    def self.add(key, &block)
      @@resevations[key] = block
    end

  end

end
