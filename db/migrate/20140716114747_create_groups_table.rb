class CreateGroupsTable < ActiveRecord::Migration
  def change

    create_table :groups do |t|
      t.string :name
      t.string :image_path
    end

    remove_column :schedules, :group_name
    add_column :schedules, :group_id, :integer

  end
end
