# frozen_string_literal: true

require 'bullet'

module Bullet
  extend self

  def request
    start_request
    yield
  ensure
    end_request
  end
end
