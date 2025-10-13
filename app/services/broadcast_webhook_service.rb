# frozen_string_literal: true

class BroadcastWebhookService < BaseService
  include ActionPolicy::Behaviour

  authorize :account
  authorize :environment

  def initialize(event:, account:, environment:, resource:, meta: nil)
    @event       = event
    @account     = account
    @environment = environment
    @resource    = resource
    @meta        = meta
  end

  def call
    selected_endpoint_ids = []

    webhook_endpoints = account.webhook_endpoints.preload(product: { role: :permissions }).for_environment(
      environment,
      strict: true,
    )

    # skip resources that our endpoint's product aren't authorized to read (if any)
    webhook_endpoints.find_each do |webhook_endpoint|
      next unless
        webhook_endpoint.subscribed?(event)

      action  = resource.class < Enumerable ? :index? : :show?
      context = {
        bearer: webhook_endpoint.product, # s/bearer/actor/
      }

      # assert either 1) it's not a product endpoint or 2) the product is allowed
      # to read the resource being sent in the webhook event
      next unless
        webhook_endpoint.product.nil? || allowed_to?(action, resource, context:)

      selected_endpoint_ids << webhook_endpoint.id
    end

    # skip if there are no relevant endpoints
    return if
      selected_endpoint_ids.empty?

    # render resource while we have it
    renderer_options = { meta: meta&.transform_keys { it.to_s.camelize(:lower) } }.compact
    renderer         = Keygen::JSONAPI::Renderer.new(
      api_version: CURRENT_API_VERSION,
      context: :webhook,
      account:,
    )

    resource_payload = renderer.render(resource, renderer_options)
                               .as_json

    CreateWebhookEventsWorker2.perform_async(
      event,
      selected_endpoint_ids,
      resource_payload,
      account.id,
      environment&.id,
    )
  rescue => e
    Keygen.logger.exception(e)

    # FIXME(ezekg) this is for tests since jobs are run inline
    raise if e in WebhookWorker::FailedRequestError
  end

  private

  attr_reader :event,
              :account,
              :environment,
              :resource,
              :meta
end
