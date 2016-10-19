class Account < ApplicationRecord
  include ActiveModel::Validations
  include Resourcifiable
  include Paginatable
  include Activatable
  include Billable

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
  has_one :billing, as: :customer, dependent: :destroy

  accepts_nested_attributes_for :users
  accepts_nested_attributes_for :billing

  before_create -> { self.subdomain = subdomain.downcase }
  after_create :set_founding_users_to_admin_roles
  after_create :send_activation_email

  validates :plan, presence: { message: "must exist" }
  validates :users, length: { minimum: 1, message: "must have at least one admin user" }
  validates_associated :billing, message: -> (_, obj) { obj[:value].errors.full_messages.first.downcase }

  validates_each :users, :products, :policies, :licenses, if: :activated? do |account, record|
    next unless account.send(record).size > account.plan.send("max_#{record}")
    account.errors.add record, "count has reached maximum allowed by current plan"
  end

  validates :name, presence: true
  validates :subdomain, subdomain: true, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 255 }

  scope :plan, -> (id) { where plan: Plan.decode_id(id) }

  private

  def set_founding_users_to_admin_roles
    users.each do |user|
      user.remove_role :user
      user.add_role :admin
    end
  end
end
