class ScheduleModuleNameChangeToMediaName < ActiveRecord::Migration
  def change
    rename_column :schedules, :module_name, :media_name
  end
end
