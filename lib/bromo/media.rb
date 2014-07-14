
require 'bromo/media/base'

Dir[File.expand_path('../media', __FILE__) << '/*.rb'].each do |file|
  require file
end

