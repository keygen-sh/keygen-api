# frozen_string_literal: true

class ReleaseEngine < ApplicationRecord
  include Limitable
  include Orderable
  include Pageable

  def self.pypi = find_by(key: 'pypi')
end