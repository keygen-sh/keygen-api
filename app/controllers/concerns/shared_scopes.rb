module SharedScopes
  extend ActiveSupport::Concern

  included do
    has_scope :limit, default: 10, only: [:index, :search] do |controller, resource, limit|
      if resource.respond_to?(:lim)
        resource.lim limit
      else
        raise Keygen::Error::InvalidScopeError.new(parameter: "limit"), "limit is not supported for this resource"
      end
    end

    has_scope :order, default: "desc", only: :index do |controller, resource, sort|
      case sort.to_s.upcase
      when "DESC"
        resource.reorder "created_at DESC"
      when "ASC"
        resource.reorder "created_at ASC"
      else
        raise Keygen::Error::InvalidScopeError.new(parameter: "order"), "order is invalid or unsupported for this resource"
      end
    end

    # Kaminari's pagination will override any limit that was set previously,
    # so we're placing it after the limit scope.
    has_scope :page, type: :hash, using: [:number, :size], only: [:index, :search] do |controller, resource, *args|
      if resource.respond_to?(:page)
        resource.page *args
      else
        raise Keygen::Error::InvalidScopeError.new(parameter: "page"), "page is not supported for this resource"
      end
    end
  end
end
