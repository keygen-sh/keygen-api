# frozen_string_literal: true

class BaseService
  def call
    raise NotImplementedError, '#call must be implemented by the service'
  end

  def self.call(...)
    new(...).call
  end
end
