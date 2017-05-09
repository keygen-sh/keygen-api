class Account < ApplicationRecord
  include ActiveModel::Validations
  include Welcomeable
  include Sluggable
  include Limitable
  include Pageable
  include Billable

  belongs_to :plan
  has_many :webhook_endpoints, dependent: :destroy
  has_many :webhook_events, dependent: :destroy
  has_many :metrics, dependent: :destroy
  has_many :tokens, dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :policies, dependent: :destroy
  has_many :keys, dependent: :destroy
  has_many :licenses, dependent: :destroy
  has_many :machines, dependent: :destroy
  has_one :billing, dependent: :destroy

  accepts_nested_attributes_for :users

  before_create -> { self.slug = slug.downcase }
  after_create :set_founding_users_roles

  validates :plan, presence: { message: "must exist" }
  validates :users, length: { minimum: 1, message: "must have at least one admin user" }

  # validates_each :users, :products, :policies, :licenses, if: :active? do |account, record|
  #   next unless account.send(record).size > account.plan.send("max_#{record}")
  #   account.errors.add record, "count has reached maximum allowed by current plan"
  # end

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { case_sensitive: false }, format: { with: /\A[-a-z0-9]+\z/, message: "can only contain lowercase letters, numbers and dashes" }, length: { maximum: 255 }, exclusion: { in: Sluggable::EXCLUDED_SLUGS, message: "is reserved" }

  scope :plan, -> (id) { where plan: id }

  def protected?
    protected
  end

  def admins
    users.admins
  end

  private

  def set_founding_users_roles
    users.each { |u| u.grant :admin }
  end
end

# == Schema Information
#
# Table name: accounts
#
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  slug       :string
#  id         :uuid             not null, primary key
#  plan_id    :uuid
#  protected  :boolean          default(FALSE)
#
# Indexes
#
#  index_accounts_on_created_at_and_id_and_slug  (created_at,id,slug) UNIQUE
#  index_accounts_on_created_at_and_plan_id      (created_at,plan_id)
#  index_accounts_on_created_at_and_slug         (created_at,slug) UNIQUE
#  index_accounts_on_slug                        (slug) UNIQUE
#
