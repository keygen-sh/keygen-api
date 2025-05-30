class SeedAccountForRoles < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!
  verbose!

  BATCH_SIZE = 1_000

  def up
    update_count = nil
    batch_count  = 0

    until update_count == 0
      batch_count  += 1
      update_count  = exec_update(<<~SQL.squish, batch_count:, batch_size: BATCH_SIZE)
        WITH batch AS (
          SELECT
            COALESCE(u.account_id, e.account_id, p.account_id, l.account_id) AS account_id,
            r.id AS role_id
          FROM
            roles r
            LEFT JOIN users        u ON r.resource_type = 'User'        AND r.resource_id = u.id
            LEFT JOIN environments e ON r.resource_type = 'Environment' AND r.resource_id = e.id
            LEFT JOIN products     p ON r.resource_type = 'Product'     AND r.resource_id = p.id
            LEFT JOIN licenses     l ON r.resource_type = 'License'     AND r.resource_id = l.id
          WHERE
            r.account_id IS NULL AND (
              u.account_id IS NOT NULL OR
              e.account_id IS NOT NULL OR
              p.account_id IS NOT NULL OR
              l.account_id IS NOT NULL
            )
          LIMIT
            :batch_size
        )
        UPDATE
          roles
        SET
          account_id = batch.account_id
        FROM
          batch
        WHERE
          roles.id = batch.role_id
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
          roles
        SET
          account_id = NULL
        WHERE
          roles.id IN (
            SELECT
              roles.id
            FROM
              roles
            WHERE
              roles.account_id IS NOT NULL
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
