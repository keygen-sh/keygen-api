# frozen_string_literal: true

module ReleaseEngines::Oci
  class ReleasePackagePolicy < ::ReleasePackagePolicy
    scope_for :active_record_relation do |relation|
      relation = relation.for_environment(environment, strict: environment.nil?)

      # FIXME(ezekg) docker expects a 401 Unauthorized response with an WWW-Authenticate
      #              challenge, so unfortunately, we can't scope relations like we
      #              usually do because then we'll respond with 404.
      relation.all
    end
  end
end
