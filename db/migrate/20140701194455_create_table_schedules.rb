class CreateTableSchedules < ActiveRecord::Migration
  def change

    create_table :schedules do |t|
      t.string :module_name
      t.string :channel_name
      t.string :title
      t.string :description

      t.integer :from_time
      t.integer :to_time

      t.string :finger_print # for search text

      t.integer :recorded # 0: not recorded, 1: now recording, 2: recorded

      t.string :file_path
      t.string :image_path

      t.string :reserved_1
      t.string :reserved_2
      t.string :reserved_3

    end
  end
end
