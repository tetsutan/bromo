require 'rbconfig'

Bromo::Config.configure do |config|
  config.use :all
  # config.port 7971
  # config.debug true
  config.remove_protection_when_sending_data true

  config.ffmpeg_options = {
    # ffmpeg -i base.mp4 -b:v 200k -b:a 64k -movflags +faststart -vcodec libx264 -f mpegts ./hoge.mp4
    video_bitrate: 200,
    audio_bitrate: 64,
    video_codec: "libx264",
    custom: "-movflags +faststart",
  }

  # mac
  # if RbConfig::CONFIG["host_os"] =~ /darwin(.+)$/
  #   config.ffmpeg_options["audio_codec"] = "libfaac"
  # end

  # # use global when development
  # config.port 7970
  # config.host "www13228ue.sakura.ne.jp"
end

# Bromo::QueueManager.add('test') do
#   media(:ag).search('BromoTest').reserve!
# end

Bromo::QueueManager.add('horie') do
  image! 'http://www.starchild.co.jp/artist/horie/images/main.png'
  search('堀江').search("由衣").reserve!
end

# radiko
Bromo::QueueManager.add('radiko-anime') do
  image! "https://pbs.twimg.com/media/CN0zJ-QUcAA7hIf.png"

  # 宮野真守のRADIO SMILE
  media(:radiko).channel(:QRR).search('宮野真守').day(:sunday).reserve!

end

# ag
Bromo::QueueManager.add('ag') do
  image! "http://www.agqr.jp/img/banner/agmobile.jpg"

  # 井上麻里奈・下田麻美のIT革命！
  media(:ag).search('革命').day(:tuesday).reserve!

  # 戸松遥のココロ☆ハルカス
  media(:ag).search('戸松').time_between(:sunday, "0000", "0100").reserve!

end

Bromo::QueueManager.add('ag-video') do
  image! "http://cdn-agqr.joqr.jp/img/logo_main_ov.png"
  # 小澤亜李・長縄まりあのおざなり
  media(:ag).search('おざなり').time_between(:saturday, "1900", "2000").reserve!(video: true)
end



# onsen
Bromo::QueueManager.add('onsen') do
  image! "http://icon.nimg.jp/channel/ch615.jpg?1405655177"

  # ARIA The Station Memoria
  media(:onsen).search('ARIA').reserve!
end


# hibiki
Bromo::QueueManager.add('hibiki') do
  image! "http://image.hibiki-radio.jp/images/toppage/logo.jpg"

  # 浅沼晋太郎・鷲崎健の「思春期が終わりません」
  media(:hibiki).search('浅沼').reserve!
end

Bromo::QueueManager.add('voice-other') do
  search('久野').search('美咲').reserve!
end

