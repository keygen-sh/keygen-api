puts "Database: #{ActiveRecord::Base.connection.current_database}"

def to_insert_sql_for(record)
  values = record.send(:attributes_with_values, record.class.column_names)
  model  = record.class

  substitutes_and_binds = values.transform_keys { model.arel_table[_1] }
  insert_manager        = Arel::InsertManager.new(model.arel_table)

  insert_manager.insert substitutes_and_binds

  model.connection.unprepared_statement do
    model.connection.to_sql(insert_manager)
  end
end

File.open 'releases.sql', 'w' do |file|
  file << "BEGIN;\n"

  puts "Dumping #{Release.count} releases…"

  Release.find_each do |release|
    file << to_insert_sql_for(release)
    file << ";\n"
  end

  puts "Dumping #{ReleaseArtifact.count} artifacts…"

  ReleaseArtifact.find_each do |artifact|
    file << to_insert_sql_for(artifact)
    file << ";\n"
  end

  puts "Dumping #{ReleasePlatform.count} platforms…"

  ReleasePlatform.find_each do |platform|
    file << to_insert_sql_for(platform)
    file << ";\n"
  end

  puts "Dumping #{ReleaseChannel.count} channels…"

  ReleaseChannel.find_each do |channel|
    file << to_insert_sql_for(channel)
    file << ";\n"
  end

  puts "Dumping #{ReleaseFiletype.count} filetypes…"

  ReleaseFiletype.find_each do |filetype|
    file << to_insert_sql_for(filetype)
    file << ";\n"
  end

  file << "COMMIT;\n"
end

puts 'Done'
