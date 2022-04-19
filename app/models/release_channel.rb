# frozen_string_literal: true

class ReleaseChannel < ApplicationRecord
  include Limitable
  include Orderable
  include Pageable

  belongs_to :account,
    inverse_of: :release_channels
  has_many :releases,
    inverse_of: :channel
  has_many :products,
    through: :releases
  has_many :licenses,
    through: :products
  has_many :users,
    through: :licenses

  validates :key,
    presence: true,
    uniqueness: { message: 'already exists', scope: :account_id },
    inclusion: { in: %w[stable rc beta alpha dev] }

  scope :for_product, -> id {
    distinct.from(
      joins(:products).where(products: { id: id })
                      .distinct_on(:id)
                      .reorder(:id),
      table_name,
    )
  }

  scope :for_user, -> user {
    distinct.from(
      joins(products: %i[users])
        .where(
          products: { distribution_strategy: ['LICENSED', nil] },
          users: { id: user },
        )
        .union(
          self.open
        )
        .distinct_on(:id)
        .reorder(:id),
      table_name,
    )
  }

  scope :for_license, -> license {
    distinct.from(
      joins(products: %i[licenses])
        .where(
          products: { distribution_strategy: ['LICENSED', nil] },
          licenses: { id: license },
        )
        .union(
          self.open
        )
        .distinct_on(:id)
        .reorder(:id),
      table_name,
    )
  }

  scope :licensed, -> {
    distinct.from(
      joins(:products).where(products: { distribution_strategy: ['LICENSED', nil] })
                      .distinct_on(:id)
                      .reorder(:id),
      table_name,
    )
  }

  scope :open, -> {
    distinct.from(
      joins(:products).where(products: { distribution_strategy: 'OPEN' })
                      .distinct_on(:id)
                      .reorder(:id),
      table_name,
    )
  }

  scope :closed, -> {
    distinct.from(
      joins(:products).where(products: { distribution_strategy: 'CLOSED' })
                      .distinct_on(:id)
                      .reorder(:id),
      table_name,
    )
  }

  def stable?
    key == 'stable'
  end

  def pre_release?
    !stable?
  end

  def rc?
    key == 'rc'
  end

  def beta?
    key == 'beta'
  end

  def alpha?
    key == 'alpha'
  end

  def dev?
    key == 'dev'
  end
end
