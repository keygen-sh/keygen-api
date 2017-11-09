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
  has_many :users, index_errors: true, dependent: :destroy
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

  validate on: [:create, :update] do
    errors.add :slug, "cannot resemble a UUID" if slug =~ UUID_REGEX
  end

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
#  id         :uuid             not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  slug       :string
#  plan_id    :uuid
#  protected  :boolean          default(FALSE)
#
# Indexes
#
#  index_accounts_on_id_and_created_at       (id,created_at) UNIQUE
#  index_accounts_on_plan_id_and_created_at  (plan_id,created_at)
#  index_accounts_on_slug                    (slug) UNIQUE
#  index_accounts_on_slug_and_created_at     (slug,created_at) UNIQUE
#
