require 'active_record'

module Bromo
  module Model
    class Schedule < ActiveRecord::Base

      def save_since_finger_print_not_exist
        if Model::Schedule.where("finger_print = '#{self.finger_print}'").size == 0
          save
        end
      end

    end
  end
end
