# frozen_string_literal: true

class ReleaseManifestPolicy < ApplicationPolicy
  skip_pre_check :verify_authenticated!, only: %i[index? show?]

  # NOTE(ezekg) manifests essentially just defer to the artifact right now
  scope_for :active_record_relation do |relation|
    relation = relation.for_environment(environment) if
      relation.respond_to?(:for_environment)

    case bearer
    in role: Role(:admin | :developer | :read_only | :sales_agent | :support_agent)
      relation.all
    in role: Role(:environment) if relation.respond_to?(:for_environment)
      relation.for_environment(bearer.id)
    in role: Role(:product) if relation.respond_to?(:for_product)
      relation.for_product(bearer.id)
    in role: Role(:user) if relation.respond_to?(:for_user)
      relation.for_user(bearer.id)
              .published
              .uploaded
    in role: Role(:license) if relation.respond_to?(:for_license)
      relation.for_license(bearer.id)
              .published
              .uploaded
    else
      relation.open.without_constraints
                   .published
                   .uploaded
    end
  end

  def index?
    verify_environment!(
      strict: false,
    )

    allow? :index, record.collect(&:artifact), with: ::ReleaseArtifactPolicy
  end

  def show?
    verify_environment!(
      strict: false,
    )

    allow? :show, record.artifact, with: ::ReleaseArtifactPolicy
  end
end
