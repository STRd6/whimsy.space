Sequel.migration do
  change do
    create_table :people do
      Integer :id, primary: true
      String :email, null: false, unique: true
      String :domain, null: false, unique: true
      String :persistent_token, null: false, unique: true
    end
  end
end
