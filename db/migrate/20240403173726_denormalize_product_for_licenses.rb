class DenormalizeProductForLicenses < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  BATCH_SIZE = 10_000

  def up
    update_count = nil
    batch_count  = 0

    until update_count == 0
      batch_count  += 1
      update_count  = exec_update(<<~SQL.squish, batch_count:, batch_size: BATCH_SIZE)
        WITH batch AS (
          SELECT
            licenses.id AS license_id,
            policies.product_id
          FROM
            licenses
            INNER JOIN policies ON policies.id = licenses.policy_id
          WHERE
            licenses.product_id IS NULL
          LIMIT
            :batch_size
        )
        UPDATE
          licenses
        SET
          product_id = batch.product_id
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
          product_id = NULL
        WHERE
          licenses.id IN (
            SELECT
              licenses.id
            FROM
              licenses
            WHERE
              licenses.product_id IS NOT NULL
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
