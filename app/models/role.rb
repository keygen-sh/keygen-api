# frozen_string_literal: true

class Role < ApplicationRecord
  USER_ROLES    = %w[user admin developer read_only sales_agent support_agent].freeze
  PRODUCT_ROLES = %w[product].freeze
  LICENSE_ROLES = %w[license].freeze
  ROLE_RANK     = {
    admin:         6,
    developer:     5,
    product:       4,
    sales_agent:   3,
    support_agent: 2,
    read_only:     1,
    license:       0,
    user:          0,
  }.with_indifferent_access
   .freeze

  belongs_to :resource,
    polymorphic: true

  # NOTE(ezekg) Sanity check
  validates :resource_type,
    inclusion: { in: [User.name, Product.name, License.name] }

  validates :name,
    inclusion: { in: USER_ROLES, message: 'must be a valid user role' },
    if: -> { resource.is_a?(User) }
  validates :name,
    inclusion: { in: PRODUCT_ROLES, message: 'must be a valid product role' },
    if: -> { resource.is_a?(Product) }
  validates :name,
    inclusion: { in: LICENSE_ROLES, message: 'must be a valid license role' },
    if: -> { resource.is_a?(License) }

  def rank
    ROLE_RANK.fetch(name) { -1 }
  end

  def <=(comparison_role)
    rank <= comparison_role.rank
  end

  def <(comparison_role)
    rank < comparison_role.rank
  end

  def >=(comparison_role)
    rank >= comparison_role.rank
  end

  def >(comparison_role)
    rank > comparison_role.rank
  end
end
