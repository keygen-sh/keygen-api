# frozen_string_literal: true

module ReleaseEngines::Oci
  class ReleaseManifestPolicy < ::ReleaseManifestPolicy
    # NOIE(ezekg) because docker expects WWW-Authenticate challenges, we can't scope like
    #             we usually do, so we'll apply some bare-minimum scoping and then do
    #             the rest of the asserts in the controller and policy.
    scope_for :active_record_relation do |relation|
      relation = relation.for_environment(environment)

      case bearer
      in role: Role(:admin | :developer | :read_only | :sales_agent | :support_agent)
        relation.all
      in role: Role(:environment)
        relation.for_environment(bearer.id)
      in role: Role(:product)
        relation.for_product(bearer.id)
      else
        relation.published
                .uploaded
      end
    end
  end
end
