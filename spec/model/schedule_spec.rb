
describe Bromo::Media::Radiko do

  it 'can write/read' do
    schedule = Bromo::Model::Schedule.new
    schedule.title = "test title"
    expect(schedule.save).to be_truthy
    expect(Bromo::Model::Schedule.first).not_to be_nil
  end

end

