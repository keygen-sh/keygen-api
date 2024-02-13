puts "Database: #{ActiveRecord::Base.connection.current_database}"

def to_insert_sql_for(record)
  values = record.send(:attributes_with_values, record.class.column_names)
  model  = record.class

  insert_manager        = Arel::InsertManager.new(model.arel_table)
  substitutes_and_binds = values.transform_keys { model.arel_table[_1] }
                                .transform_values { |value|
                                  case value.type
                                  in ActiveRecord::Encryption::EncryptedAttributeType
                                    value.value
                                  else
                                    value
                                  end
                                }

  insert_manager.insert(substitutes_and_binds)

  model.connection.unprepared_statement do
    model.connection.to_sql(insert_manager)
  end
end

account = Account.find(
  ENV.fetch('ACCOUNT_ID'),
)

File.open "tmp/export-#{account.slug}.sql", 'w' do |file|
  file << "BEGIN;\n"

  puts "Exporting account #{account.id}…"

  file << to_insert_sql_for(account)
  file << ";\n"

  puts "Exporting #{account.entitlements.count} entitlements…"

  account.entitlements.find_each do |entitlement|
    file << to_insert_sql_for(entitlement)
    file << ";\n"
  end

  puts "Exporting #{account.products.count} products…"

  account.products.find_each do |product|
    file << to_insert_sql_for(product)
    file << ";\n"
  end

  puts "Exporting #{account.policies.count} policies…"

  account.policies.find_each do |policy|
    file << to_insert_sql_for(policy)
    file << ";\n"
  end

  puts "Exporting #{account.users.to_a.size} users…"

  account.users.find_each do |user|
    file << to_insert_sql_for(user)
    file << ";\n"
  end

  puts "Exporting #{account.licenses.count} licenses…"

  account.licenses.find_each do |license|
    file << to_insert_sql_for(license)
    file << ";\n"
  end

  puts "Exporting #{account.machines.to_a.size} machines…"

  account.machines.find_each do |machine|
    file << to_insert_sql_for(machine)
    file << ";\n"
  end

  file << "COMMIT;\n"
end

puts 'Done'
