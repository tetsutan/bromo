class FixStringToText < ActiveRecord::Migration
  def change
    change_column :groups, :name, :text
    change_column :groups, :image_path, :text
    change_column :schedules, :title, :text
    change_column :schedules, :description, :text
    change_column :schedules, :finger_print, :text
    change_column :schedules, :file_path, :text
    change_column :schedules, :image_path, :text
    change_column :schedules, :reserved_1, :text
    change_column :schedules, :reserved_2, :text
    change_column :schedules, :reserved_3, :text
    change_column :schedules, :search_text, :text
  end
end
