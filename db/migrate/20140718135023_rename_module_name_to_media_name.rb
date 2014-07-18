class RenameModuleNameToMediaName < ActiveRecord::Migration
  def change
    rename_table :module_informations, :media_informations
    rename_column :media_informations, :module_name, :media_name
  end
end
