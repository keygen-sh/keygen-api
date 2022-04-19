# frozen_string_literal: true

class ReleasePlatform < ApplicationRecord
  include Limitable
  include Orderable
  include Pageable

  belongs_to :account,
    inverse_of: :release_platforms
  has_many :releases,
    inverse_of: :platform
  has_many :products,
    through: :releases
  has_many :licenses,
    through: :products
  has_many :users,
    through: :licenses

  validates :key,
    presence: true,
    uniqueness: { message: 'already exists', scope: :account_id }

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

  scope :with_releases, -> {
    distinct.from(
      joins(products: %i[releases]).distinct_on(:id).reorder(:id),
      table_name,
    )
  }
end
