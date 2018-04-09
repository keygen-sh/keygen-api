class AddGinIndexesToResources < ActiveRecord::Migration[5.0]
  INDEXES = {
    products: ['id', 'name', 'metadata'],
    policies: ['id', 'name', 'metadata'],
    licenses: ['id', 'key', 'metadata'],
    machines: ['id', 'fingerprint', 'name', 'metadata'],
    users: ['id', 'email', 'first_name', 'last_name', 'metadata'],
    keys: ['id', 'key']
  }

  def up
    INDEXES.each do |table, columns|
      columns.each do |column|
        add_column table, "tsv_#{column}", :tsvector
        add_index table, "tsv_#{column}", using: :gin

        execute <<-SQL.squish
          CREATE FUNCTION update_#{table}_#{column}_tsvector() RETURNS trigger AS $$
          BEGIN
            new.tsv_#{column} :=
              to_tsvector('pg_catalog.simple', coalesce(new.#{column}::TEXT, ''));

            RETURN new;
          END
          $$ LANGUAGE plpgsql;

          CREATE TRIGGER tsvector_trigger_#{table}_#{column} BEFORE INSERT OR UPDATE OF #{column}
            ON #{table} FOR EACH ROW EXECUTE PROCEDURE
            update_#{table}_#{column}_tsvector();
        SQL
      end

      update "UPDATE #{table} SET id = id"
    end
  end

  def down
    INDEXES.each do |table, columns|
      columns.each do |column|
        execute <<-SQL.squish
          DROP TRIGGER tsvector_trigger_#{table}_#{column} ON #{table};
          DROP FUNCTION update_#{table}_#{column}_tsvector();
        SQL

        remove_index table, "tsv_#{column}"
        remove_column table, "tsv_#{column}"
      end
    end
  end
end
