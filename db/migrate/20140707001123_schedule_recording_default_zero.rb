class ScheduleRecordingDefaultZero < ActiveRecord::Migration
  def change
    change_column :schedules, :recorded, :integer, :default => 0
  end
end
