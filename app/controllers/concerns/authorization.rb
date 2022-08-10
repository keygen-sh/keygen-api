module Authorization
  extend ActiveSupport::Concern

  # To prevent mistakes, alias and remove the default Pundit authorize method.
  included do
    alias_method :pundit_authorize, :authorize
    remove_possible_method :authorize
  end

  ##
  # authorize! adds a layer on top of Pundit that better supports
  # namespaced policies, e.g. Product::TokenPolicy, by providing
  # context via an authorization resource.
  #
  # Provide a policy: if e.g. the subject is nillable, to prevent
  # a 404 from being raised, while still authorizing nil.
  def authorize!(*resources, policy: nil, action: "#{action_name}?")
    *context, subject = resources

    authz_resource = AuthorizationResource.new(subject:, context:)
    policy_class   = case policy
                     when NilClass
                       Pundit.policy!(authorization_context, resources)
                             .class
                     when String
                       policy.constantize
                     else
                       policy
                     end

    pundit_authorize(authz_resource, action, policy_class:)
  end
end
