# frozen_string_literal: true

class SeedBearerRoleForTokens < ActiveRecord::Migration[8.1]
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
            tokens.id  AS token_id,
            roles.name AS role_name
          FROM
            tokens
          INNER JOIN
            roles ON roles.resource_type = tokens.bearer_type AND
                     roles.resource_id   = tokens.bearer_id
          WHERE
            tokens.bearer_role IS NULL
          LIMIT
            :batch_size
        )
        UPDATE
          tokens
        SET
          bearer_role = batch.role_name
        FROM
          batch
        WHERE
          tokens.id = batch.token_id
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
          tokens
        SET
          bearer_role = NULL
        WHERE
          tokens.id IN (
            SELECT
              tokens.id
            FROM
              tokens
            WHERE
              tokens.bearer_role IS NOT NULL
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
