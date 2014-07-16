
require 'active_record'
require 'digest/sha1'

module Bromo
  module Model
    class Group < ActiveRecord::Base
      has_many :schedules
    end
  end
end

