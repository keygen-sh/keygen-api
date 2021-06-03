# Steps to recover

- Determine time of event for resource deletion (e.g. product, policy, etc.)
- Download copy of database before time of event minus 1 minute (see: https://devcenter.heroku.com/articles/heroku-postgres-rollback#common-use-case-recovery-after-critical-data-loss)
- Export data from database copy for resource via recovery script

## Recovery example

```ruby
puts "Database: #{ActiveRecord::Base.connection.current_database}"

def to_insert_sql_for(record)
  values = record.send(:attributes_with_values, record.class.column_names)
  model = record.class
  substitutes_and_binds = model.send(:_substitute_values, values)

  insert_manager = model.arel_table.create_insert
  insert_manager.insert substitutes_and_binds

  conn = model.connection

  conn.unprepared_statement do
    sql = conn.to_sql(insert_manager)
  end
end

File.open 'recover.sql', 'w' do |file|
  puts "Loading account #{ENV['ACCOUNT_ID']}…"

  account = Account.find ENV['ACCOUNT_ID']

  puts "Recovering product #{ENV['PRODUCT_ID']}…"

  product = account.products.find ENV['PRODUCT_ID']

  file << "BEGIN;\n"

  file << to_insert_sql_for(product)
  file << ";\n"

  puts "Recovering #{product.policies.count} policies…"

  product.policies.each do |policy|
    file << to_insert_sql_for(policy)
    file << ";\n"
  end

  puts "Recovering #{product.tokens.count} product tokens…"

  product.tokens.each do |token|
    file << to_insert_sql_for(token)
    file << ";\n"
  end

  puts "Recovering #{product.licenses.count} licenses…"

  product.licenses.each do |license|
    file << to_insert_sql_for(license)
    file << ";\n"

    license.tokens.each do |token|
      file << to_insert_sql_for(token)
      file << ";\n"
    end
  end

  puts "Recovering #{product.machines.to_a.size} machines…"

  product.machines.each do |machine|
    file << to_insert_sql_for(machine)
    file << ";\n"
  end

  file << "COMMIT;\n"
end

puts 'Done'
```

```bash
heroku addons:create heroku-postgresql:standard-0 --rollback HEROKU_POSTGRESQL_MAUVE_URL --to '2021-06-03 07:27 UTC'
heroku pg:wait
spring stop
DATABASE_URL=$(heroku config:get HEROKU_POSTGRESQL_CHARCOAL_URL) ACCOUNT_ID={} PRODUCT_ID={} rails runner .scripts/recover.rb
cat .scripts/recover.sql | heroku pg:psql >> .scripts/recover.log
```
