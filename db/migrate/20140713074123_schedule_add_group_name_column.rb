class ScheduleAddGroupNameColumn < ActiveRecord::Migration
  def change
    add_column :schedules, :group_name, :string
  end
end
