require 'bromo/model'
module Bromo
  class Queue

    def initialize(schedule)
      @schedule = schedule
    end

    def time_to_left
      1000
    end

  end
end
