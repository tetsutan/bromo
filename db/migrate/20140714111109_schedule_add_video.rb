class ScheduleAddVideo < ActiveRecord::Migration
  def change
    add_column :schedules, :video, :integer
  end
end
