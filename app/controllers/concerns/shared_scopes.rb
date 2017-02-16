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

    has_scope :order, default: "desc", only: :index do |controller, resource, sort|
      case sort.to_s.upcase
      when "DESC"
        resource.reorder "created_at DESC"
      when "ASC"
        resource.reorder "created_at ASC"
      end
    end

    # Kaminari's pagination will override any limit that was set previously,
    # so we're placing it after the limit scope.
    has_scope :page, type: :hash, using: [:number, :size], only: :index
  end
end
