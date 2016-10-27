class RoleValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    record.errors.add attribute, "must be a valid role" unless valid_role?(record.resource, value)
  end

  private

  def valid_role?(resource, value)
    return false if resource.nil? || value.nil?
    resource.allowed_roles&.include? value
  end
end
