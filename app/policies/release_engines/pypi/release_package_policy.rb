# frozen_string_literal: true

module ReleaseEngines::Pypi
  class ReleasePackagePolicy < ::ReleasePackagePolicy
    scope_for :active_record_relation do |relation|
      relation = relation.for_environment(environment)

      # NOTE(ezekg) See comment in simple controller. We don't want to use our normal authz scoping
      #             and raise a not found error for packages that do exist but aren't accessible
      #             by the current bearer, even if that avoids leaking information. Rather, we
      #             want to return an authz error to avoid redirecting to PyPI.
      relation.all
    end
  end
end
