class AddFilesystem < ActiveRecord::Migration
  def up
    add_column :people, :filesystem, :json

    execute "ALTER TABLE people ALTER COLUMN filesystem SET DEFAULT '[]'::JSON"
  end

  def down
    remove_column :people, :filesystem
  end
end
