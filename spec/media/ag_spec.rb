
describe Bromo::Media::Ag do

  before :each do
    cheat_bromo_core

    @ag = Bromo::Media::Ag.new

    @schedule = Bromo::Model::Schedule.new
    @schedule.media_name = "ag"
    @schedule.title = "#{@schedule.media_name} Title"
    @schedule.description = "#{@schedule.media_name} Description"

    @schedule.from_time = Time.now.to_i + 5
    @schedule.to_time = @schedule.from_time + 10
    @schedule.save

  end

  it 'can record' do
    file_name = @ag.record(@schedule)
    expect(file_name).to be_truthy

    file = File.join(Bromo::Config.data_dir, file_name)
    expect(File).to be_readable(file)
  end


end

