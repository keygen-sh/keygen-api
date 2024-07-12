# frozen_string_literal: true

Rails.autoloaders.each do |autoloader|
  # FIXME(ezekg) Should we rename these to follow conventions?
  autoloader.inflector.inflect(
    "digest_io" => "DigestIO",
    "jsonapi" => "JSONAPI",
    "ee" => "EE",
  )
end
