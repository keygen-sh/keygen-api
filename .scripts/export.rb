# SECRET_KEY_BASE=$(heroku config:get SECRET_KEY_BASE) ENCRYPTION_DETERMINISTIC_KEY=$(heroku config:get ENCRYPTION_DETERMINISTIC_KEY) ENCRYPTION_PRIMARY_KEY=$(heroku config:get ENCRYPTION_PRIMARY_KEY) ENCRYPTION_KEY_DERIVATION_SALT=$(heroku config:get ENCRYPTION_KEY_DERIVATION_SALT) DATABASE_URL=$(heroku config:get DATABASE_URL) ACCOUNT_ID= rails runner .scripts/export.rb

puts "Database: #{ActiveRecord::Base.connection.current_database}"

EXPORT_AT  = Time.current
BATCH_SIZE = 1_000

def to_insert_sql_for(*records, model: records.first.class, table: model.arel_table)
  manager = Arel::InsertManager.new(table)
  values  = []

  model.column_names.each do |column|
    manager.columns << model.arel_table[column]
  end

  records.each do |record|
    attributes_with_values = record.send(:attributes_with_values, model.column_names)

    values << attributes_with_values.values.collect { |attribute|
      case attribute.type
      in ActiveRecord::Encryption::EncryptedAttributeType
        attribute.value # get the unencrypted value
      else
        attribute.value_for_database
      end
    }
  end

  manager.values = manager.create_values_list(
    values,
  )

  manager.to_sql
end

account = Account.find(
  ENV.fetch('ACCOUNT_ID'),
)

File.open "tmp/export-#{account.slug}.sql", 'w' do |file|
  file << "BEGIN;\n"

  file << "-- account #{account.slug} at #{EXPORT_AT}\n"

  file << to_insert_sql_for(account)
  file << ";\n"

  account.class.reflect_on_all_associations(:has_many).each do |reflection|
    next if
      reflection.name in :webhook_events | :request_logs | :event_logs | :metrics

    association = account.association(reflection.name)
    scope       = association.scope

    file << "-- #{scope.count} #{reflection.name}\n"

    scope.in_batches(of: BATCH_SIZE) do |batch|
      file << to_insert_sql_for(*batch)
      file << ";\n"
    end
  end

  file << "COMMIT;\n"
end

puts 'Done'
