# frozen_string_literal: true

class Plan < ApplicationRecord
  include Limitable
  include Pageable

  has_many :accounts

  scope :visible, -> { where private: false }
  scope :hidden, -> { where private: true }
  scope :paid, -> { where 'price > 0' }
  scope :free, -> { where 'price IS NULL OR price = 0' }

  def private?
    private
  end

  def public?
    !private
  end

  def free?
    price.nil? || price.zero?
  end

  def paid?
    !free?
  end

  def ent?
    name.starts_with?('Ent')
  end
end
