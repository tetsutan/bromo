class CreateTableModuleInformations < ActiveRecord::Migration
  def change

    create_table :module_informations do |t|
      t.string :module_name
      t.timestamps
    end

  end
end
