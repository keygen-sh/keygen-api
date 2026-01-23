# frozen_string_literal: true

class << ENV
  EMPTY_STRING = ''.freeze

  def true?(key)  = fetch(key) { EMPTY_STRING }.to_bool
  def false?(key) = !true?(key)
end
