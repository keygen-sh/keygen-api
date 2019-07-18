# frozen_string_literal: true

class Plan < ApplicationRecord
  include Limitable
  include Pageable

  has_many :accounts

  scope :visible, -> { where private: false }
  scope :hidden, -> { where private: true }

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
end
