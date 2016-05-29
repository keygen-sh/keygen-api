class BaseSerializer < ActiveModel::Serializer

  # Transform JSON response keys from Rails-conventional snake_case to
  # JSON-conventional camelCase
  #
  # @see /config/initializers/json_param_key_transform
  # @see /app/controllers/api/v*/api_controller
  # @see /app/serializers/base_serializer
  #
  def attributes(*args)
    Hash[super.map do |key, value|
      [key.to_s.camelize(:lower).to_sym, value]
    end]
  end
end
