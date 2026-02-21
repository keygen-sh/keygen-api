# frozen_string_literal: true

require 'bullet'

module Bullet
  extend self

  # be still my ocd... be still...
  def started? = start?

  def request
    start_request if enabled?
    yield
  ensure
    end_request if started?
  end
end
