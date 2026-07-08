# frozen_string_literal: true

class SeedBearerRoleForTokens < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!
  verbose!

  BATCH_SIZE = 10_000
  MIN_UUID   = '00000000-0000-0000-0000-000000000000'

  def up
    cursor      = MIN_UUID
    batch_count = 0

    # NB(ezekg) we paginate via a keyset cursor on the primary key because the
    #           bearer_role predicate has no supporting index, and without a
    #           cursor each batch would rescan the table from the start, e.g.
    #           past tokens left NULL because their bearer has no role
    loop do
      batch_count += 1
      token_ids    = exec_query(<<~SQL.squish, cursor:, batch_count:, batch_size: BATCH_SIZE).rows.flatten
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
            tokens.bearer_role IS NULL AND
            tokens.id > :cursor
          ORDER BY
            tokens.id
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
        RETURNING
          tokens.id
        /* batch=:batch_count */
      SQL

      break if
        token_ids.empty?

      cursor = token_ids.max
    end
  end

  def down
    cursor      = MIN_UUID
    batch_count = 0

    loop do
      batch_count += 1
      token_ids    = exec_query(<<~SQL.squish, cursor:, batch_count:, batch_size: BATCH_SIZE).rows.flatten
        WITH batch AS (
          SELECT
            tokens.id AS token_id
          FROM
            tokens
          WHERE
            tokens.bearer_role IS NOT NULL AND
            tokens.id > :cursor
          ORDER BY
            tokens.id
          LIMIT
            :batch_size
        )
        UPDATE
          tokens
        SET
          bearer_role = NULL
        FROM
          batch
        WHERE
          tokens.id = batch.token_id
        RETURNING
          tokens.id
        /* batch=:batch_count */
      SQL

      break if
        token_ids.empty?

      cursor = token_ids.max
    end
  end

  private

  def exec_query(sql, **binds)
    ActiveRecord::Base.connection.exec_query(
      ActiveRecord::Base.sanitize_sql([sql, **binds]),
    )
  end
end
