Sequel.migration do
  change do
    create_table :people do
      String :email, primary_key: true
      String :domain, null: false, unique: true
    end
  end
end
