class DenormalizePolicyForMachines < ActiveRecord::Migration[7.2]
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
            machines.id AS machine_id,
            licenses.policy_id
          FROM
            machines
            INNER JOIN licenses ON licenses.id = machines.license_id
          WHERE
            machines.policy_id IS NULL
          LIMIT
            :batch_size
        )
        UPDATE
          machines
        SET
          policy_id = batch.policy_id
        FROM
          batch
        WHERE
          machines.id = batch.machine_id
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
          machines
        SET
          policy_id = NULL
        WHERE
          machines.id IN (
            SELECT
              machines.id
            FROM
              machines
            WHERE
              machines.policy_id IS NOT NULL
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
