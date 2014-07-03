require 'rspec'
require 'bromo'


describe 'Time to next XX' do

  it 'should be next +1 -1 hour/min' do

    now = Time.now

    now_hour = now.hour
    # +1 hour
    if(now_hour < 23)
      expect(Bromo::Utils::Date.next("#{now.hour+1}00") - Time.now).to be > 0
    end

    # -1 hour
    if(1 < now_hour)
      expect(Bromo::Utils::Date.next("#{now.hour-1}00") - Time.now).to be > 0
    end


    now_min = now.min
    # +1 min
    if(now_min < 59)
      min = (now.min+1).to_s
      min = "0#{min}" if(min.size == 1)
      expect(Bromo::Utils::Date.next("#{now.hour}#{min}") - Time.now).to be > 0
    end

    # -1 min
    if(1 < now_min)
      min = (now.min-1).to_s
      min = "0#{min}" if(min.size == 1)
      expect(Bromo::Utils::Date.next("#{now.hour}#{min}") - Time.now).to be > 0
    end

  end

end

