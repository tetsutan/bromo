class ScheduleAddSearchText < ActiveRecord::Migration
  def change
    add_column :schedules, :search_text, :string
  end
end
