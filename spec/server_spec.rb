require 'rack/test'
require 'nokogiri'
require 'pp'

describe Bromo::Server do
  extend Rack::Test::Methods

  def app
    Bromo::Server
  end

  before :each do


  end

  def new_schedule_template

    group = Bromo::Model::Group.find_or_create_by(name: "debug")

    schedule = Bromo::Model::Schedule.new
    schedule.media_name = "radiko"
    schedule.channel_name = "LFR"
    schedule.title = "#{schedule.media_name} Title"
    schedule.description = "#{schedule.media_name} Description"

    schedule.from_time = Time.now.to_i + 5
    schedule.to_time = schedule.from_time + 10

    schedule.group = group
    schedule
  end

  describe "/status" do
    it "without data" do
      get '/status'
      expect(last_response).to be_ok
    end

    it "have one schedule" do
      new_schedule_template.save
      get '/status'
      expect(last_response).to be_ok
    end
  end

  describe "/list/*" do

    it "without data" do

      new_schedule_template # but not save

      get '/list/debug.xml'
      expect(last_response).to be_ok

      doc = Nokogiri::XML(last_response.body)
      expect(doc.xpath("/rss/channel/item").size).to eq(0)
    end

    it "have one schedule" do

      schedule = new_schedule_template
      schedule.recorded = Bromo::Model::Schedule::RECORDED_RECORDED
      schedule.file_path = "test.mp3"
      schedule.save

      group_name = schedule.group.name

      expect(Bromo::Model::Schedule.recorded_by_group(group_name).size).to eq(1)

      get "/list/#{group_name}.xml"
      expect(last_response).to be_ok

      doc = Nokogiri::XML(last_response.body)
      expect(doc.xpath("/rss/channel/item").size).to eq(1)

    end


  end

end

