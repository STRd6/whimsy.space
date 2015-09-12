class CreatePeople < ActiveRecord::Migration
  def change
    create_table :people do |t|
      t.string :email, null: false
      t.string :domain, null: false
      t.string :persistent_token, null: false
    end

    add_index :people, :email, unique: true
    add_index :people, :domain, unique: true
    add_index :people, :persistent_token, unique: true
  end
end
