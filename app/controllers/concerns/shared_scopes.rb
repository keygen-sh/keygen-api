module SharedScopes
  extend ActiveSupport::Concern

  included do

    has_scope :limit, default: 10, only: :index do |controller, resource, limit|
      if resource.respond_to?(:lim)
        resource.lim limit
      else
        resource
      end
    end

    # Kaminari's pagination will override any limit that was set previously,
    # so we're placing it after the limit scope.
    has_scope :page, type: :hash, using: [:number, :size], only: :index
  end
end
