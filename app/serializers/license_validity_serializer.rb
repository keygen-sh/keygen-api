class LicenseValiditySerializer < BaseSerializer
  attributes :is_valid

  def is_valid
    object.license_valid?
  end
end
