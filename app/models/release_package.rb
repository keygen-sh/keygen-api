# frozen_string_literal: true

class ReleasePackage
  include ActiveModel::Model

  class << self
    def for(products) = products.map { ReleasePackage.new(_1) }
  end

  attr_reader :product

  def initialize(product, artifacts: nil)
    @product   = product
    @artifacts = artifacts
  end

  delegate :id, :code, :name, :metadata,
    to: :product

  def artifacts
    @artifacts ||= product.release_artifacts
  end
end