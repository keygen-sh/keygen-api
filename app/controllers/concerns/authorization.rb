module Authorization
  extend ActiveSupport::Concern

  # To prevent mistakes, alias and remove the default Pundit authorize method.
  included do
    alias_method :pundit_authorize, :authorize
    remove_possible_method :authorize
  end

  # authorize! adds a layer on top of Pundit that better supports
  # namespaced policies, e.g. ProductPolicy::TokenPolicy, and by
  # providing context via an authorization resource.
  def authorize!(*resources, action: "#{action_name}?")
    *context, subject = resources

    authz_resource = AuthorizationResource.new(subject:, context:)
    policy_class   = resources.map { pundit_policy_for(_1) }
                              .join("::")
                              .constantize

    pundit_authorize(authz_resource, action, policy_class:)
  end

  private

  def pundit_policy_for(subject)
    klass = case
            when subject.respond_to?(:model_name)
              subject.model_name
            when subject.class.respond_to?(:model_name)
              subject.class.model_name
            when subject.is_a?(Class)
              subject
            when subject.is_a?(Symbol)
              subject.to_s.camelize
            else
              subject.class
            end

    "#{klass}Policy"
  end
end
