class Account < ApplicationRecord
  include ActiveModel::Validations
  include Paginatable
  include Limitable
  include Billable

  acts_as_paranoid

  belongs_to :plan
  has_many :webhook_endpoints, dependent: :destroy
  has_many :webhook_events, dependent: :destroy
  has_many :tokens, dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :policies, dependent: :destroy
  has_many :keys, dependent: :destroy
  has_many :licenses, dependent: :destroy
  has_many :machines, dependent: :destroy
  has_one :billing, dependent: :destroy

  accepts_nested_attributes_for :users

  before_create -> { self.subdomain = subdomain.downcase }
  after_create :set_founding_users_roles
  after_create :initialize_billing

  validates :plan, presence: { message: "must exist" }
  validates :users, length: { minimum: 1, message: "must have at least one admin user" }

  # validates_each :users, :products, :policies, :licenses, if: :active? do |account, record|
  #   next unless account.send(record).size > account.plan.send("max_#{record}")
  #   account.errors.add record, "count has reached maximum allowed by current plan"
  # end

  validates :name, presence: true
  validates :subdomain, subdomain: true, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 255 }

  scope :plan, -> (id) { where plan: Plan.decode_id(id) }

  def admins
    users.admins
  end

  private

  def set_founding_users_roles
    users.each { |u| u.grant :admin }
  end

  def initialize_billing
    InitializeBillingWorker.perform_async id
  rescue Redis::CannotConnectError
    false
  end
end

# == Schema Information
#
# Table name: accounts
#
#  id                 :integer          not null, primary key
#  name               :string
#  subdomain          :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  plan_id            :integer
#  activation_token   :string
#  activation_sent_at :datetime
#  deleted_at         :datetime
#
# Indexes
#
#  index_accounts_on_deleted_at  (deleted_at)
#  index_accounts_on_subdomain   (subdomain)
#
