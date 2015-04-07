Sequel.migration do
  change do
    create_table :people do
      Integer :id, primary: true

      String :email, null: false, unique: true

      String :domain, null: false, unique: true
      constraint(:domain_min_length) {char_length(domain) >= 3}
      constraint(:domain_max_length) {char_length(domain) <= 16}

      String :persistent_token, null: false, unique: true
    end
  end
end
