# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root / 'lib' / 'union_of'

describe UnionOf do
  let(:account) { create(:account) }
  let(:record)  { create(:user, account:) } # FIXME(ezekg) Replace with temporary table when we extract into a gem
  let(:model)   { record.class }

  it 'should create an association reflection' do
    expect(model.reflect_on_all_associations).to satisfy { |associations|
      associations in [
        *,
        UnionOf::Reflection(
          name: :licenses,
          options: {
            sources: %i[owned_licenses user_licenses],
          },
        ),
        *
      ]
    }
  end

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

  it 'should return the correct relations' do
    user = create(:user, account:)

    owned_license_1 = create(:license, account:, owner: user)
    user_license_1  = create(:license, account:)
    user_license_2  = create(:license, account:)
    other_license   = create(:license, account:)

    create(:license_user, account:, license: user_license_1, user:)
    create(:license_user, account:, license: user_license_1)
    create(:license_user, account:, license: user_license_2, user:)
    create(:license_user, account:, license: user_license_2)

    expect(user.licenses).to eq [owned_license_1, user_license_1, user_license_2]
  end

  it 'should return the correct relation ids' do
    user = create(:user, account:)

    owned_license_1 = create(:license, account:, owner: user)
    user_license_1  = create(:license, account:)
    user_license_2  = create(:license, account:)
    other_license   = create(:license, account:)

    create(:license_user, account:, license: user_license_1, user:)
    create(:license_user, account:, license: user_license_1)
    create(:license_user, account:, license: user_license_2, user:)
    create(:license_user, account:, license: user_license_2)

    expect(user.licenses.ids).to eq [owned_license_1.id, user_license_1.id, user_license_2.id]
    expect(user.license_ids).to eq [owned_license_1.id, user_license_1.id, user_license_2.id]
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
          )
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
          )
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
          )
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

  describe 'querying' do
    it 'should support querying a union' do
      user           = create(:user, account:)
      other_user     = create(:user, account:)
      owned_license  = create(:license, account:, owner: user)
      user_license_1 = create(:license, account:)
      user_license_2 = create(:license, account:)

      create(:license_user, account:, license: owned_license, user: other_user)
      create(:license_user, account:, license: user_license_1, user:)
      create(:license_user, account:, license: user_license_2, user:)

      expect(owned_license.users.count).to eq 2
      expect(owned_license.users).to satisfy { _1 in [user, other_user] }

      expect(user.licenses.count).to eq 3
      expect(user.licenses).to satisfy { _1 in [owned_license, user_license_1, user_license_2] }
      expect(user.licenses.where.not(id: owned_license)).to satisfy { _1 in [user_license_1, user_license_2] }
      expect(user.licenses.where(id: owned_license).count).to eq 1

      expect(other_user.licenses.count).to eq 1
      expect(other_user.licenses).to satisfy { _1 in [owned_license] }
    end

    it 'should support querying a through union' do
      product_1 = create(:product, account:)
      product_2 = create(:product, account:)
      policy_1  = create(:policy, account:, product: product_1)
      policy_2  = create(:policy, account:, product: product_2)

      user           = create(:user, account:)
      other_user     = create(:user, account:)
      owned_license  = create(:license, account:, policy: policy_1, owner: user)
      user_license_1 = create(:license, account:, policy: policy_2)
      user_license_2 = create(:license, account:, policy: policy_2)

      create(:license_user, account:, license: owned_license, user: other_user)
      create(:license_user, account:, license: user_license_1, user:)
      create(:license_user, account:, license: user_license_2, user:)

      machine_1 = create(:machine, license: user_license_1, owner: user)
      machine_2 = create(:machine, license: user_license_2, owner: user)
      machine_3 = create(:machine, license: owned_license, owner: user)
      machine_4 = create(:machine, license: owned_license, owner: other_user)

      expect(user.products.count).to eq 2
      expect(user.products).to satisfy { _1 in [product_1, product_2] }

      expect(user.machines.count).to eq 4
      expect(user.machines.owned.count).to eq 3
      expect(user.machines).to satisfy { _1 in [machine_1, machine_2, machine_3, machine_4] }
      expect(user.machines.owned).to satisfy { _1 in [machine_1, machine_2, machine_3] }
      expect(user.machines.where.not(id: machine_3)).to satisfy { _1 in [machine_1, machine_2, machine_4] }
      expect(user.machines.where(id: machine_3).count).to eq 1

      expect(other_user.machines.count).to eq 2
      expect(other_user.machines.owned.count).to eq 1
      expect(other_user.machines).to satisfy { _1 in [machine_1, machine_4] }
      expect(other_user.machines.owned).to satisfy { _1 in [machine_4] }

      expect(user.teammates.count).to eq 1
      expect(user.teammates).to satisfy { _1 in [other_user] }

      expect(other_user.teammates.count).to eq 1
      expect(other_user.teammates).to satisfy { _1 in [user] }
    end
  end

  describe 'preloading' do
    before do
      # user with no licenses
      create(:user, account:)

      # license with no owner
      license = create(:license, account:)

      create(:machine, account:, license:)

      # user with owned license
      owner   = create(:user, account:, created_at: 1.year.ago)
      license = create(:license, account:, owner:, created_at: 1.week.ago)

      create(:machine, account:, license:, owner:)

      # user with user license
      user    = create(:user, account:, created_at: 1.minute.ago)
      license = create(:license, account:, created_at: 1.month.ago)

      create(:license_user, account:, license:, user:, created_at: 2.weeks.ago)
      create(:machine, account:, license:, created_at: 1.week.ago)

      # user with 2 user licenses
      user    = create(:user, account:, created_at: 1.week.ago)
      license = create(:license, account:, created_at: 1.week.ago)

      create(:license_user, account:, license:, user:, created_at: 1.week.ago)
      create(:machine, account:, license:, owner: user, created_at: 1.second.ago)

      license = create(:license, account:, created_at: 1.year.ago)

      create(:license_user, account:, license:, user:, created_at: 1.year.ago)

      # user with 1 owned and 2 user licenses
      user    = create(:user, account:, created_at: 1.week.ago)
      license = create(:license, account:, owner:, created_at: 1.week.ago)

      license = create(:license, account:, created_at: 1.week.ago)

      create(:license_user, account:, license:, user:, created_at: 1.week.ago)
      create(:machine, account:, license:, owner: user, created_at: 1.second.ago)

      license = create(:license, account:, created_at: 1.year.ago)

      create(:license_user, account:, license:, user:, created_at: 1.year.ago)

      # license with owner and 2 users
      owner   = create(:user, account:, created_at: 1.year.ago)
      license = create(:license, account:, owner:, created_at: 1.year.ago)

      create(:machine, account:, license:, owner:)

      user = create(:user, account:, created_at: 1.week.ago)
      create(:license_user, account:, license:, user:, created_at: 1.week.ago)
      create(:machine, account:, license:, owner: user)

      user = create(:user, account:, created_at: 1.year.ago)
      create(:license_user, account:, license:, user:, created_at: 1.year.ago)
      create(:machine, account:, license:, owner: user)
    end

    it 'should support eager loading a union' do
      licenses = License.eager_load(:users)

      expect(licenses.to_sql).to match_sql <<~SQL.squish
        SELECT
          "licenses"."id" AS t0_r0,
          "licenses"."key" AS t0_r1,
          "licenses"."expiry" AS t0_r2,
          "licenses"."created_at" AS t0_r3,
          "licenses"."updated_at" AS t0_r4,
          "licenses"."metadata" AS t0_r5,
          "licenses"."user_id" AS t0_r6,
          "licenses"."policy_id" AS t0_r7,
          "licenses"."account_id" AS t0_r8,
          "licenses"."suspended" AS t0_r9,
          "licenses"."last_check_in_at" AS t0_r10,
          "licenses"."last_expiration_event_sent_at" AS t0_r11,
          "licenses"."last_check_in_event_sent_at" AS t0_r12,
          "licenses"."last_expiring_soon_event_sent_at" AS t0_r13,
          "licenses"."last_check_in_soon_event_sent_at" AS t0_r14,
          "licenses"."uses" AS t0_r15,
          "licenses"."protected" AS t0_r16,
          "licenses"."name" AS t0_r17,
          "licenses"."machines_count" AS t0_r18,
          "licenses"."last_validated_at" AS t0_r19,
          "licenses"."machines_core_count" AS t0_r20,
          "licenses"."max_machines_override" AS t0_r21,
          "licenses"."max_cores_override" AS t0_r22,
          "licenses"."max_uses_override" AS t0_r23,
          "licenses"."group_id" AS t0_r24,
          "licenses"."max_processes_override" AS t0_r25,
          "licenses"."last_check_out_at" AS t0_r26,
          "licenses"."environment_id" AS t0_r27,
          "licenses"."last_validated_checksum" AS t0_r28,
          "licenses"."last_validated_version" AS t0_r29,
          "users"."id" AS t1_r0,
          "users"."email" AS t1_r1,
          "users"."password_digest" AS t1_r2,
          "users"."created_at" AS t1_r3,
          "users"."updated_at" AS t1_r4,
          "users"."password_reset_token" AS t1_r5,
          "users"."password_reset_sent_at" AS t1_r6,
          "users"."metadata" AS t1_r7,
          "users"."account_id" AS t1_r8,
          "users"."first_name" AS t1_r9,
          "users"."last_name" AS t1_r10,
          "users"."stdout_unsubscribed_at" AS t1_r11,
          "users"."stdout_last_sent_at" AS t1_r12,
          "users"."banned_at" AS t1_r13,
          "users"."group_id" AS t1_r14,
          "users"."environment_id" AS t1_r15
        FROM
          "licenses"
          LEFT OUTER JOIN "users" ON "users"."id" IN (
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
            )
          )
        ORDER BY
          "licenses"."created_at" ASC
      SQL


      licenses.each do |license|
        expect(license.association(:users).loaded?).to be true
        expect(license.association(:owner).loaded?).to be false
        expect(license.association(:licensees).loaded?).to be false

        expect { license.users }.to_not make_database_queries
        expect(license.users.sort_by(&:id)).to eq license.reload.users.sort_by(&:id)
      end
    end

    it 'should support eager loading a through union' do
      users = User.eager_load(:machines)

      expect(users.to_sql).to match_sql <<~SQL.squish
        SELECT
          "users"."id" AS t0_r0,
          "users"."email" AS t0_r1,
          "users"."password_digest" AS t0_r2,
          "users"."created_at" AS t0_r3,
          "users"."updated_at" AS t0_r4,
          "users"."password_reset_token" AS t0_r5,
          "users"."password_reset_sent_at" AS t0_r6,
          "users"."metadata" AS t0_r7,
          "users"."account_id" AS t0_r8,
          "users"."first_name" AS t0_r9,
          "users"."last_name" AS t0_r10,
          "users"."stdout_unsubscribed_at" AS t0_r11,
          "users"."stdout_last_sent_at" AS t0_r12,
          "users"."banned_at" AS t0_r13,
          "users"."group_id" AS t0_r14,
          "users"."environment_id" AS t0_r15,
          "machines"."id" AS t1_r0,
          "machines"."fingerprint" AS t1_r1,
          "machines"."ip" AS t1_r2,
          "machines"."hostname" AS t1_r3,
          "machines"."platform" AS t1_r4,
          "machines"."created_at" AS t1_r5,
          "machines"."updated_at" AS t1_r6,
          "machines"."name" AS t1_r7,
          "machines"."metadata" AS t1_r8,
          "machines"."account_id" AS t1_r9,
          "machines"."license_id" AS t1_r10,
          "machines"."last_heartbeat_at" AS t1_r11,
          "machines"."cores" AS t1_r12,
          "machines"."last_death_event_sent_at" AS t1_r13,
          "machines"."group_id" AS t1_r14,
          "machines"."max_processes_override" AS t1_r15,
          "machines"."last_check_out_at" AS t1_r16,
          "machines"."environment_id" AS t1_r17,
          "machines"."heartbeat_jid" AS t1_r18,
          "machines"."owner_id" AS t1_r19
        FROM
          "users"
          LEFT OUTER JOIN "licenses" ON "licenses"."id" IN (
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
            )
          )
          LEFT OUTER JOIN "machines" ON "machines"."license_id" = "licenses"."id"
        ORDER BY
          "users"."created_at" ASC
      SQL

      users.each do |user|
        expect(user.association(:machines).loaded?).to be true
        expect(user.association(:licenses).loaded?).to be false

        expect { user.machines }.to_not make_database_queries
        expect(user.machines.sort_by(&:id)).to eq user.reload.machines.sort_by(&:id)
      end
    end

    it 'should support preloading a union' do
      licenses = License.preload(:users)

      # FIXME(ezekg) How can I test the actual SQL used for preloading?
      expect { licenses.to_a }.to make_database_queries(count: 6)
        .and not_raise_error

      licenses.each do |license|
        expect(license.association(:users).loaded?).to be true
        expect(license.association(:owner).loaded?).to be true
        expect(license.association(:licensees).loaded?).to be true

        expect { license.users }.to_not make_database_queries
        expect(license.users.sort_by(&:id)).to eq license.reload.users.sort_by(&:id)
      end
    end

    it 'should support preloading a through union' do
      users = User.preload(:machines)

      # FIXME(ezekg) How can I test the actual SQL used for preloading?
      expect { users.to_a }.to make_database_queries(count: 5)
        .and not_raise_error

      users.each do |user|
        expect(user.association(:machines).loaded?).to be true
        expect(user.association(:licenses).loaded?).to be true

        expect { user.machines }.to_not make_database_queries
        expect(user.machines.sort_by(&:id)).to eq user.reload.machines.sort_by(&:id)
      end
    end
  end

  describe UnionOf::Macro do
    subject do
      Class.new ActiveRecord::Base do
        def self.table_name = 'users'
        def self.name       = 'User'

        include UnionOf::Macro

        has_many :owned_licenses
        has_many :license_users
        has_many :user_licenses, through: :license_users
      end
    end

    describe '.union_of' do
      it 'should respond' do
        expect(subject.respond_to?(:union_of)).to be true
      end

      it 'should not raise' do
        expect { subject.union_of :licenses, sources: %i[owned_licenses user_licenses] }.to_not raise_error
      end

      it 'should define' do
        subject.union_of :licenses, sources: %i[owned_licenses user_licenses]

        expect(subject.reflect_on_association(:licenses)).to_not be nil
        expect(subject.reflect_on_association(:licenses).macro).to eq :union_of
        expect(subject.reflect_on_union(:licenses)).to_not be nil
        expect(subject.reflect_on_union(:licenses).macro).to eq :union_of
      end
    end

    describe '.has_many' do
      it 'should respond' do
        expect(subject.respond_to?(:has_many)).to be true
      end

      it 'should not raise' do
        expect { subject.has_many :licenses, union_of: %i[owned_licenses user_licenses] }.to_not raise_error
      end

      it 'should define' do
        subject.has_many :licenses, union_of: %i[owned_licenses user_licenses]

        expect(subject.reflect_on_association(:licenses)).to_not be nil
        expect(subject.reflect_on_association(:licenses).macro).to eq :union_of
        expect(subject.reflect_on_union(:licenses)).to_not be nil
        expect(subject.reflect_on_union(:licenses).macro).to eq :union_of
      end
    end
  end

  describe UnionOf::ReadonlyAssociation do
    it 'should not raise on readers' do
      expect { record.licenses }.to_not raise_error
      expect { record.licenses.first }.to_not raise_error
      expect { record.licenses.last }.to_not raise_error
      expect { record.licenses.forty_two }.to_not raise_error
      expect { record.licenses.take }.to_not raise_error
    end

    it 'should not raise on query methods' do
      expect { record.licenses.find_by(id: SecureRandom.uuid) }.to_not raise_error
      expect { record.licenses.where(name: 'Foo') }.to_not raise_error
    end

    it 'should not raise on ID readers' do
      expect { record.licenses.ids }.to_not raise_error
      expect { record.license_ids }.to_not raise_error
    end

    it 'should raise on IDs writer' do
      expect { record.license_ids = [] }.to raise_error UnionOf::ReadonlyAssociationError
    end

    it 'should raise on build' do
      expect { record.licenses.build(id: SecureRandom.uuid) }.to raise_error UnionOf::ReadonlyAssociationError
      expect { record.licenses.new(id: SecureRandom.uuid) }.to raise_error UnionOf::ReadonlyAssociationError
    end

    it 'should raise on create' do
      expect { record.licenses.create!(id: SecureRandom.uuid) }.to raise_error UnionOf::ReadonlyAssociationError
      expect { record.licenses.create(id: SecureRandom.uuid) }.to raise_error UnionOf::ReadonlyAssociationError
    end

    it 'should raise on insert' do
      expect { record.licenses.insert!(id: SecureRandom.uuid) }.to raise_error UnionOf::ReadonlyAssociationError
      expect { record.licenses.insert(id: SecureRandom.uuid) }.to raise_error UnionOf::ReadonlyAssociationError
      expect { record.licenses.insert_all!([]) }.to raise_error UnionOf::ReadonlyAssociationError
      expect { record.licenses.insert_all([]) }.to raise_error UnionOf::ReadonlyAssociationError
    end

    it 'should raise on upsert' do
      expect { record.licenses.upsert(id: SecureRandom.uuid) }.to raise_error UnionOf::ReadonlyAssociationError
      expect { record.licenses.upsert_all([]) }.to raise_error UnionOf::ReadonlyAssociationError
    end

    it 'should raise on update' do
      expect { record.licenses.update_all(id: SecureRandom.uuid) }.to raise_error UnionOf::ReadonlyAssociationError
      expect { record.licenses.update!(id: SecureRandom.uuid) }.to raise_error UnionOf::ReadonlyAssociationError
      expect { record.licenses.update(id: SecureRandom.uuid) }.to raise_error UnionOf::ReadonlyAssociationError
    end

    it 'should raise on delete' do
      expect { record.licenses.delete_all }.to raise_error UnionOf::ReadonlyAssociationError
      expect { record.licenses.delete(SecureRandom.uuid) }.to raise_error UnionOf::ReadonlyAssociationError
    end

    it 'should raise on destroy' do
      expect { record.licenses.destroy_all }.to raise_error UnionOf::ReadonlyAssociationError
      expect { record.licenses.destroy(SecureRandom.uuid) }.to raise_error UnionOf::ReadonlyAssociationError
    end
  end

  # TODO(ezekg) Add exhaustive tests for all association macros, e.g.
  #             belongs_to, has_many, etc.
end
