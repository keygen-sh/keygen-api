# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root / 'lib' / 'union_of'

describe UnionOf do
  let(:account) { create(:account) }
  let(:record)  { create(:user, account:) } # FIXME(ezekg) Replace with temporary table when we extract into a gem
  let(:model)   { record.class }

  it 'should create a union reflection' do
    expect(model.reflect_on_all_unions).to satisfy { |unions|
      unions in [
        UnionOf::Reflection(
          name: :licenses,
          options: {
            sources: %i[owned_licenses user_licenses],
          },
        ),
      ]
    }
  end

  it 'should be a relation' do
    expect(record.licenses).to be_an ActiveRecord::Relation
  end

  it 'should be a union' do
    expect(record.licenses.to_sql).to match_sql <<~SQL.squish
      SELECT
        "licenses".*
      FROM
        "licenses"
      WHERE
        "licenses"."id" IN (
          SELECT
            "licenses"."id"
          FROM
            (
              (
                SELECT
                  "licenses"."id"
                FROM
                  "licenses"
                WHERE
                  "licenses"."user_id" = '#{record.id}'
              )
              UNION
              (
                SELECT
                  "licenses"."id"
                FROM
                  "licenses"
                  INNER JOIN "license_users" ON "licenses"."id" = "license_users"."license_id"
                WHERE
                  "license_users"."user_id" = '#{record.id}'
              )
            ) "licenses"
        )
      ORDER BY
        "licenses"."created_at" ASC
    SQL
  end

  it 'should not raise on shallow join' do
    expect { model.joins(:licenses).to_a }.to_not raise_error
  end

  it 'should not raise on deep join' do
    expect { model.joins(:machines).to_a }.to_not raise_error
  end

  it 'should produce a union join' do
    expect(model.joins(:machines).to_sql).to match_sql <<~SQL.squish
      SELECT
        "users".*
      FROM
        "users"
        INNER JOIN "licenses" ON "licenses"."id" IN (
          SELECT
            "licenses"."id"
          FROM
            (
              (
                SELECT
                  "licenses"."id"
                FROM
                  "licenses"
                WHERE
                  "licenses"."user_id" = "users"."id"
              )
              UNION
              (
                SELECT
                  "licenses"."id"
                FROM
                  "licenses"
                  INNER JOIN "license_users" ON "licenses"."id" = "license_users"."license_id"
                  AND "users"."id" = "license_users"."user_id"
              )
            ) "licenses"
        )
        INNER JOIN "machines" ON "machines"."license_id" = "licenses"."id"
        ORDER BY
          "users"."created_at" ASC
    SQL
  end

  it 'should produce a union query' do
    # TODO(ezekg) Add DISTINCT?
    expect(record.machines.to_sql).to match_sql <<~SQL.squish
      SELECT
        "machines".*
      FROM
        "machines"
        INNER JOIN "licenses" ON "machines"."license_id" = "licenses"."id"
      WHERE
        "licenses"."id" IN (
          SELECT
            "licenses"."id"
          FROM
            (
              (
                SELECT
                  "licenses"."id"
                FROM
                  "licenses"
                WHERE
                  "licenses"."user_id" = '#{record.id}'
              )
              UNION
              (
                SELECT
                  "licenses"."id"
                FROM
                  "licenses"
                  INNER JOIN "license_users" ON "licenses"."id" = "license_users"."license_id"
                WHERE
                  "license_users"."user_id" = '#{record.id}'
              )
            ) "licenses"
        )
      ORDER BY
        "machines"."created_at" ASC
    SQL
  end

  it 'should produce a deep union join' do
    expect(model.joins(:components).to_sql).to match_sql <<~SQL.squish
      SELECT
        "users".*
      FROM
        "users"
        INNER JOIN "licenses" ON "licenses"."id" IN (
          SELECT
            "licenses"."id"
          FROM
            (
              (
                SELECT
                  "licenses"."id"
                FROM
                  "licenses"
                WHERE
                  "licenses"."user_id" = "users"."id"
              )
              UNION
              (
                SELECT
                  "licenses"."id"
                FROM
                  "licenses"
                  INNER JOIN "license_users" ON "licenses"."id" = "license_users"."license_id"
                  AND "users"."id" = "license_users"."user_id"
              )
            ) "licenses"
        )
        INNER JOIN "machines" ON "machines"."license_id" = "licenses"."id"
        INNER JOIN "machine_components" ON "machine_components"."machine_id" = "machines"."id"
      ORDER BY
        "users"."created_at" ASC
    SQL
  end

  it 'should produce a deep union query' do
    # TODO(ezekg) Add DISTINCT?
    expect(record.components.to_sql).to match_sql <<~SQL.squish
      SELECT
        "machine_components".*
      FROM
        "machine_components"
        INNER JOIN "machines" ON "machine_components"."machine_id" = "machines"."id"
        INNER JOIN "licenses" ON "machines"."license_id" = "licenses"."id"
      WHERE
        "licenses"."id" IN (
          SELECT
            "licenses"."id"
          FROM
            (
              (
                SELECT
                  "licenses"."id"
                FROM
                  "licenses"
                WHERE
                  "licenses"."user_id" = '#{record.id}'
              )
              UNION
              (
                SELECT
                  "licenses"."id"
                FROM
                  "licenses"
                  INNER JOIN "license_users" ON "licenses"."id" = "license_users"."license_id"
                  WHERE
                    "license_users"."user_id" = '#{record.id}'
              )
            ) "licenses"
        )
      ORDER BY
        "machine_components"."created_at" ASC
    SQL
  end

  it 'should produce a deeper union join' do
    expect(Product.joins(:users).to_sql).to match_sql <<~SQL.squish
      SELECT
        "products".*
      FROM
        "products"
        INNER JOIN "policies" ON "policies"."product_id" = "products"."id"
        INNER JOIN "licenses" ON "licenses"."policy_id" = "policies"."id"
        INNER JOIN "users" ON "users"."id" IN (
          SELECT
            "users"."id"
          FROM
            (
              (
                SELECT
                  "users"."id"
                FROM
                  "users"
                  INNER JOIN "license_users" ON "users"."id" = "license_users"."user_id"
                  AND "licenses"."id" = "license_users"."license_id"
              )
              UNION
              (
                SELECT
                  "users"."id"
                FROM
                  "users"
                WHERE
                  "users"."id" = "licenses"."user_id"
              )
            ) "users"
        )
      ORDER BY
        "products"."created_at" ASC
    SQL
  end

  it 'should produce a deeper union query' do
    product = create(:product, account:)

    expect(product.users.to_sql).to match_sql <<~SQL.squish
      SELECT
        DISTINCT "users".*
      FROM
        "users"
        INNER JOIN "licenses" ON "licenses"."id" IN (
          (
            (
              SELECT
                "licenses"."id"
              FROM
                "licenses"
                INNER JOIN "license_users" ON "users"."id" = "license_users"."user_id"
                AND "licenses"."id" = "license_users"."license_id"
            )
            UNION
            (
              SELECT
                "licenses"."id"
              FROM
                "licenses"
              WHERE
                "users"."id" = "licenses"."user_id"
            )
          )
        )
        INNER JOIN "policies" ON "licenses"."policy_id" = "policies"."id"
      WHERE
        "policies"."product_id" = '#{product.id}'
      ORDER BY
        "users"."created_at" ASC
    SQL
  end

  context 'with nil belongs_to association' do
    let(:record) { create(:license, account:) }

    it 'should not produce a union query' do
      expect(record.users.to_sql).to match_sql <<~SQL.squish
        SELECT
          "users".*
        FROM
          "users"
        WHERE
          "users"."id" IN (
            SELECT
              "users"."id"
            FROM
              (
                SELECT
                  "users"."id"
                FROM
                  "users"
                  INNER JOIN "license_users" ON "users"."id" = "license_users"."user_id"
                WHERE
                  "license_users"."license_id" = '#{record.id}'
              ) "users"
          )
        ORDER BY
          "users"."created_at" ASC
      SQL
    end
  end

  # TODO(ezekg) Add exhaustive tests for all association macros, e.g.
  #             belongs_to, has_many, etc.
end
