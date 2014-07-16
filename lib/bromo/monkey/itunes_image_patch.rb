
require 'rss'
require 'rss/2.0'
require 'rss/itunes'

require 'pp'

# RSS::Maker::ItemsBase::ItemBase.class_eval do
# end



# RSS::Rss::Channel::Item.class_eval do
#   def_class_accessor(, name, type, *additional_infos)
# end

# def_class_accessor(RSS::Rss::Channel::Item, "image", :attribute, "href")

# module RSS
#   module Rss
#     module ChannelItem.class_eval do
#   extend ActiveSupport::Concern
# 
#   alias_method_chain :append_features, :image
# 
# 
#   end
# 
#   def_class_accessor(self, "image", :attribute, "href")
# end
# 
#     class << self
#       def append_features(klass)
#         super
# 
#         return if klass.instance_of?(Module)
#         ELEMENT_INFOS.each do |name, type, *additional_infos|
#           def_class_accessor(klass, name, type, *additional_infos)
#         end
#       end
#     end
# 
#     ELEMENT_INFOS = [
#                      ["category", :elements, "categories", "text"],
#                      ["image", :attribute, "href"],
#                      ["owner", :element],
#                      ["new-feed-url"],
#                     ] + ITunesBaseModel::ELEMENT_INFOS
# 

# module RSS
#   module Maker
#     module ITunesItemModel
#       class ITunesImageBase < ITunesChannelModel::ITunesImageBase; end
#     end
# 
#     module ITunesItemModel
#       extend ActiveSupport::Concern
# 
#       included do
# 
#         class << self
#           p append_features
#           def append_features_with_image(klass)
#             p "call append_features_with_image"
#             append_features_without_image(klass)
#             def_class_accessor(klass, "image", :attribute, "href")
#           end
#           alias_method_chain :append_features, :image
#         end
#       end
#     end
# 
# 
#     class ItemsBase
#       class ItemBase
#         class ITunesImage < ITunesImageBase; end
#       end
#     end
#   end
# end

# module RSS
#   class Rss
#     class Channel
#       class Item
#         extend ActiveSupport::Concern
#         class << self
#           def append_features_with_image(klass)
#             p "call appedn_features_with_image"
#             append_features_without_image(klass)
#             def_class_accessor(klass, "image", :attribute, "href")
#           end
#           alias_method_chain :append_features, :image
#         end
#       end
#     end
#   end
# end
 



# module RSS
#   module Maker
#     class ItemsBase
#       class ItemBase
# 
# 
#         extend ActiveSupport::Concern
#         # extend ITunesModelUtils
#         # include Maker::ITunesItemModel
#         # extend ITunesBaseModel
#             # def_class_accessor(self, "image", :attribute, "href")
#         # class_eval do
#           include Maker::ITunesItemModel
#           class ITunesImage < ITunesChannelModel::ITunesImageBase; end
#           class_eval do
#           class << self
#             def append_features_with_image(klass)
#               p "call append_features_with_image"
#               append_features_without_image(klass)
#               def_class_accessor(klass, "image", :attribute, "href")
#             end
#             alias_method_chain :append_features, :image
#           end
#         end
# 
#         append_features(self)
# 
#       # end
#     end
#   end
# end
# 
# module RSS
#   class Rss
#     class Item
#       class_eval do
#         # RSS::Element.install_model("image", "", "?")
#       end
#     end
#   end
# end

RSS::ITunesItemModel::ELEMENT_INFOS << ["image", :attribute, "href"]

module RSS
  module Maker
    class ItemsBase
      class ItemBase


        extend ActiveSupport::Concern
        # extend ITunesModelUtils
        # include Maker::ITunesItemModel
        extend ITunesBaseModel
            # def_class_accessor(self, "image", :attribute, "href")
        # class ITunesImage < ITunesChannelModel::ITunesImageBase; end

        class ITunesImageBase < Base
          add_need_initialize_variable("href")
          attr_accessor("href")

          def to_feed(feed, current)

            p @href
            p current
            p current.class
            p current.respond_to?(:itunes_image)
            p current.methods

            pp caller
            p "hoge"

            if @href and current.respond_to?(:itunes_image)
              current.itunes_image ||= current.class::ITunesImage.new
              current.itunes_image.href = @href
              p current.itunes_image.href
            end
          end
        end
        class ITunesImage < ITunesImageBase; end

        class_eval do
          class << self
            def append_features_with_image(klass)
              p "call append_features_with_image"
              append_features_without_image(klass)
              def_class_accessor(klass, "image", :attribute, "href")
            end
            alias_method_chain :append_features, :image
          end
          append_features(self)
        end
        # include Maker::ITunesItemModel


      end
    end
  end
end



module RSS

  module ITunesItemModel

    extend BaseModel
    extend ITunesModelUtils
    include ITunesBaseModel

    class << self
      def append_features(klass)
        super

        return if klass.instance_of?(Module)
        ELEMENT_INFOS.each do |name, type|
          def_class_accessor(klass, name, type)
        end
      end
    end

    ELEMENT_INFOS << ["image", :attribute, "href"]

    class ITunesImage < Element
      include RSS09

      @tag_name = "image"

      class << self
        def required_prefix
          ITUNES_PREFIX
        end

        def required_uri
          ITUNES_URI
        end
      end

      [
        ["href", "", true]
      ].each do |name, uri, required|
        install_get_attribute(name, uri, required)
      end

      def initialize(*args)
        if Utils.element_initialize_arguments?(args)
          super
        else
          super()
          self.href = args[0]
        end
      end

      def full_name
        tag_name_with_prefix(ITUNES_PREFIX)
      end

      private
      def maker_target(target)
        if href
          target.itunes_image {|image| image}
        else
          nil
        end
      end

      def setup_maker_attributes(image)
        image.href = href
      end
    end
  end

  class Rss
    class Channel
      class Item
        attr_accessor :itunes_image

      end
    end
  end

end



module RSS
  module Maker
    module ITunesItemModel
      extend ITunesBaseModel

      class << self
        def append_features(klass)
          super

          ::RSS::ITunesItemModel::ELEMENT_INFOS.each do |name, type, *args|
            def_class_accessor(klass, name, type, *args)
          end
        end
      end
      class ITunesImageBase < Base
        add_need_initialize_variable("href")
        attr_accessor("href")

        def to_feed(feed, current)
          p @href
          if @href and current.respond_to?(:itunes_image)
            current.itunes_image ||= current.class::ITunesImage.new
            current.itunes_image.href = @href
          end
        end
      end

    end

  end
end


