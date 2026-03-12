# frozen_string_literal: true

class Plan < ApplicationRecord
  include Limitable
  include Orderable
  include Pageable

  has_many :accounts

  scope :visible, -> { where(private: false) }
  scope :hidden,  -> { where(private: true) }

  scope :paid, -> { where('price > 0') }
  scope :free, -> { where('price IS NULL OR price = 0') }

  scope :ent, -> { where('name LIKE ?', 'Ent%') }
  scope :std, -> { where('name LIKE ?', 'Std%') }
  scope :dev, -> { where('name LIKE ?', 'Dev%') }

  def private? = private
  def public?  = !private

  def free? = price.nil? || price.zero?
  def paid? = !free?

  def ent? = name.starts_with?('Ent')
  def std? = name.starts_with?('Std')
  def dev? = name.starts_with?('Dev')
end
