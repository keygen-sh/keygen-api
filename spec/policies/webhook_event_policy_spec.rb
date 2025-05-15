# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe WebhookEventPolicy, type: :policy do
  subject { described_class.new(record, account:, environment:, bearer:, token:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_webhook_events] do
      with_token_authentication do
        with_permissions %w[webhook-event.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }

        within_environment :isolated do
          with_bearer_and_token_trait :in_shared_environment do
            denies :index
          end

          with_bearer_and_token_trait :in_nil_environment do
            denies :index
          end

          allows :index
        end

        within_environment :shared do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :index
          end

          with_bearer_and_token_trait :in_nil_environment do
            allows :index
          end

          allows :index
        end

        within_environment nil do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :index
          end

          with_bearer_and_token_trait :in_shared_environment do
            denies :index
          end

          allows :index
        end
      end
    end

    with_scenarios %i[accessing_a_webhook_event] do
      with_token_authentication do
        with_permissions %w[webhook-event.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[webhook-event.delete] do
          without_token_permissions { denies :destroy }

          allows :destroy
        end

        with_permissions %w[webhook-event.retry] do
          without_token_permissions { denies :retry }

          allows :retry
        end

        with_wildcard_permissions do
          without_token_permissions { denies :show, :destroy, :retry }

          allows :show, :destroy, :retry
        end

        with_default_permissions do
          without_token_permissions { denies :show, :destroy, :retry }

          allows :show, :destroy, :retry
        end

        without_permissions do
          denies :show, :destroy, :retry
        end

        within_environment :isolated do
          with_bearer_and_token_trait :in_shared_environment do
            denies :show, :destroy, :retry
          end

          with_bearer_and_token_trait :in_nil_environment do
            denies :show, :destroy, :retry
          end

          allows :show, :destroy, :retry
        end

        within_environment :shared do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :show, :destroy, :retry
          end

          with_bearer_and_token_trait :in_nil_environment do
            allows :show, :destroy, :retry
          end

          allows :show, :destroy, :retry
        end

        within_environment nil do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :show, :destroy, :retry
          end

          with_bearer_and_token_trait :in_shared_environment do
            denies :show, :destroy, :retry
          end

          allows :show, :destroy, :retry
        end
      end
    end
  end

  with_role_authorization :environment do
    within_environment :self do
      with_scenarios %i[accessing_webhook_events] do
        with_token_authentication do
          with_permissions %w[webhook-event.read] do
            without_token_permissions { denies :index }

            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }

          within_environment :isolated do
            with_bearer_and_token_trait :isolated do
              allows :index
            end

            with_bearer_and_token_trait :shared do
              denies :index
            end
          end

          within_environment :shared do
            with_bearer_and_token_trait :isolated do
              denies :index
            end

            with_bearer_and_token_trait :shared do
              allows :index
            end
          end

          within_environment nil do
            with_bearer_and_token_trait :isolated do
              denies :index
            end

            with_bearer_and_token_trait :shared do
              denies :index
            end
          end
        end
      end

      with_scenarios %i[accessing_a_webhook_event] do
        with_token_authentication do
          with_permissions %w[webhook-event.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_permissions %w[webhook-event.delete] do
            without_token_permissions { denies :destroy }

            allows :destroy
          end

          with_permissions %w[webhook-event.retry] do
            without_token_permissions { denies :retry }

            allows :retry
          end

          with_wildcard_permissions do
            without_token_permissions do
              denies :show, :destroy, :retry
            end

            allows :show, :destroy, :retry
          end

          with_default_permissions do
            without_token_permissions do
              denies :show, :destroy, :retry
            end

            allows :show, :destroy, :retry
          end

          without_permissions do
            denies :show, :destroy, :retry
          end

          within_environment :isolated do
            with_bearer_and_token_trait :isolated do
              allows :show, :destroy, :retry
            end

            with_bearer_and_token_trait :shared do
              denies :show, :destroy, :retry
            end
          end

          within_environment :shared do
            with_bearer_and_token_trait :isolated do
              denies :show, :destroy, :retry
            end

            with_bearer_and_token_trait :shared do
              allows :show, :destroy, :retry
            end
          end

          within_environment nil do
            with_bearer_and_token_trait :isolated do
              denies :show, :destroy, :retry
            end

            with_bearer_and_token_trait :shared do
              denies :show, :destroy, :retry
            end
          end
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[accessing_its_webhook_events] do
      with_token_authentication do
        with_permissions %w[webhook-event.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_its_webhook_event] do
      with_token_authentication do
        with_permissions %w[webhook-event.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :destroy, :retry
          end

          denies :destroy, :retry
          allows :show
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :destroy, :retry
          end

          denies :destroy, :retry
          allows :show
        end

        without_permissions do
          denies :show, :destroy, :retry
        end
      end
    end

    with_scenarios %i[accessing_webhook_events] do
      with_token_authentication do
        with_permissions %w[webhook-event.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_webhook_event] do
      with_token_authentication do
        with_permissions %w[webhook-event.read] do
          denies :show
        end

        with_wildcard_permissions do
          denies :show, :destroy, :retry
        end

        with_default_permissions do
          denies :show, :destroy, :retry
        end

        without_permissions do
          denies :show, :destroy, :retry
        end
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[accessing_webhook_events] do
      with_license_authentication do
        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end

      with_token_authentication do
        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_webhook_event] do
      with_license_authentication do
        with_wildcard_permissions do
          denies :show, :destroy, :retry
        end

        with_default_permissions do
          denies :show, :destroy, :retry
        end

        without_permissions do
          denies :show, :destroy, :retry
        end
      end

      with_token_authentication do
        with_wildcard_permissions do
          denies :show, :destroy, :retry
        end

        with_default_permissions do
          denies :show, :destroy, :retry
        end

        without_permissions do
          denies :show, :destroy, :retry
        end
      end
    end
  end

  with_role_authorization :user do
    with_scenarios %i[accessing_webhook_events] do
      with_token_authentication do
        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_webhook_event] do
      with_token_authentication do
        with_wildcard_permissions do
          denies :show, :destroy, :retry
        end

        with_default_permissions do
          denies :show, :destroy, :retry
        end

        without_permissions do
          denies :show, :destroy, :retry
        end
      end
    end
  end

  without_authorization do
    with_scenarios %i[accessing_webhook_events] do
      without_authentication { denies :index }
    end

    with_scenarios %i[accessing_a_webhook_event] do
      without_authentication { denies :show, :destroy, :retry }
    end
  end
end
