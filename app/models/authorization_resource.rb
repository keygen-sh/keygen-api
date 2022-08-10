# frozen_string_literal: true

class AuthorizationResource
  class InvalidSubjectError < StandardError; end

  ##
  # AuthorizationResource is used to store an authorization context
  # for Pundit policies. As a simple example:
  #
  #   resource = AuthorizationResource.new(subject: license)
  #
  # This class also allows the + policy to authorize namespaced
  # resources, like this:
  #
  #   authorize! license, entitlements
  #
  # Which will be instantiated as:
  #
  #   new(subject: entitlements, context: [license])
  #
  # And the authz resource and its data can be accessed within the
  # Pundit policy, like below:
  #
  #   def license     = resource.context.first
  #   def entitlement = resource.subject
  #
  #   def show?
  #     license.product == bearer &&
  #     license.has?(entitlement)
  #   end
  #
  # This makes namespaced policies much easier to use.
  attr_reader :subject,
              :context

  def initialize(subject:, context: [])
    @subject = subject
    @context = context
  end
end
