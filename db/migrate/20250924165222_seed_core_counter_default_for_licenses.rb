class SeedCoreCounterDefaultForLicenses < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!
  verbose!

  BATCH_SIZE = 10_000

  def up
    update_count = nil
    batch_count  = 0

    until update_count == 0
      batch_count  += 1
      update_count  = exec_update(<<~SQL.squish, batch_count:, batch_size: BATCH_SIZE)
        WITH batch AS (
          SELECT
            licenses.id AS license_id
          FROM
            licenses
          WHERE
            licenses.machines_core_count IS NULL
          LIMIT
            :batch_size
        )
        UPDATE
          licenses
        SET
          machines_core_count = 0
        FROM
          batch
        WHERE
          licenses.id = batch.license_id
        /* batch=:batch_count */
      SQL
    end
  end

  def down
    update_count = nil
    batch_count  = 0

    until update_count == 0
      batch_count  += 1
      update_count  = exec_update(<<~SQL.squish, batch_count:, batch_size: BATCH_SIZE)
        UPDATE
          licenses
        SET
          machines_core_count = NULL
        WHERE
          licenses.id IN (
            SELECT
              licenses.id
            FROM
              licenses
            WHERE
              licenses.machines_core_count IS NOT NULL
            LIMIT
              :batch_size
          )
        /* batch=:batch_count */
      SQL
    end
  end

  private

  def exec_update(sql, **binds)
    ActiveRecord::Base.connection.exec_update(
      ActiveRecord::Base.sanitize_sql([sql, **binds]),
    )
  end
end
