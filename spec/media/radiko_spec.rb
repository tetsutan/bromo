
require Bromo::Config.rc_path if Bromo::Config.check_path
Bromo::Config.check_config

describe Bromo::Media::Radiko do

  before :each do
    @radiko = Bromo::Media::Radiko.new
  end


end

