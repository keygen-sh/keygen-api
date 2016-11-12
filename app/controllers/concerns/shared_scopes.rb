module SharedScopes
  extend ActiveSupport::Concern

  included do
    has_scope :page, type: :hash, using: [:number, :size], only: :index
    has_scope :limit, default: 10, only: :index do |controller, resource, limit|
      return resource unless resource.respond_to? :lim
      resource.lim limit.to_i
    end
  end
end
