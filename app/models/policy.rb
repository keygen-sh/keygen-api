class Policy < ApplicationRecord
  belongs_to :product
  has_many :licenses, dependent: :destroy

  serialize :pool, Array

  def pop
    begin
      return nil if pool.empty?
      v = pool.pop
      self.save!
      return v
    rescue ActiveRecord::StaleObjectError
      self.reload
      retry
    end
  end

  def <<(license_key)
    begin
      pool << license_key
      self.save!
    rescue ActiveRecord::StaleObjectError
      self.reload
      retry
    end
  end
end
