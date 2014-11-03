class ScheduleAddTimstampColumn < ActiveRecord::Migration
  def change
    change_table(:schedules) { |t| t.timestamps }
  end
end
