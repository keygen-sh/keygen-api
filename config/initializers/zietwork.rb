# frozen_string_literal: true

Rails.autoloaders.each do |autoloader|
  # FIXME(ezekg) Should we rename these to follow conventions?
  autoloader.inflector.inflect(
    "jsonapi" => "JSONAPI",
    "ee" => "EE",
  )
end
