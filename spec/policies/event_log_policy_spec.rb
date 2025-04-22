# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe EventLogPolicy, type: :policy do
  subject { described_class.new(record, account:, environment:, bearer:, token:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_event_logs] do
      with_token_authentication do
        with_permissions %w[event-log.read] do
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

    with_scenarios %i[accessing_an_event_log] do
      with_token_authentication do
        with_permissions %w[event-log.read] do
          without_token_permissions { denies :show, :count }

          allows :show, :count
        end

        with_wildcard_permissions do
          without_token_permissions { denies :show, :count }

          allows :show, :count
        end

        with_default_permissions do
          without_token_permissions { denies :show, :count }

          allows :show, :count
        end

        without_permissions do
          denies :show, :count
        end

        within_environment :isolated do
          with_bearer_and_token_trait :in_shared_environment do
            denies :show, :count
          end

          with_bearer_and_token_trait :in_nil_environment do
            denies :show, :count
          end

          allows :show, :count
        end

        within_environment :shared do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :show, :count
          end

          with_bearer_and_token_trait :in_nil_environment do
            allows :show, :count
          end

          allows :show, :count
        end

        within_environment nil do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :show, :count
          end

          with_bearer_and_token_trait :in_shared_environment do
            denies :show, :count
          end

          allows :show, :count
        end
      end
    end
  end

  with_role_authorization :environment do
    within_environment :self do
      with_scenarios %i[accessing_event_logs] do
        with_token_authentication do
          with_permissions %w[event-log.read] do
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

      with_scenarios %i[accessing_an_event_log] do
        with_token_authentication do
          with_permissions %w[event-log.read] do
            without_token_permissions { denies :show, :count }

            allows :show, :count
          end

          with_wildcard_permissions do
            without_token_permissions { denies :show, :count }

            allows :show, :count
          end

          with_default_permissions do
            without_token_permissions { denies :show, :count }

            allows :show, :count
          end

          without_permissions do
            denies :show, :count
          end

          within_environment :isolated do
            with_bearer_and_token_trait :isolated do
              allows :show, :count
            end

            with_bearer_and_token_trait :shared do
              denies :show, :count
            end
          end

          within_environment :shared do
            with_bearer_and_token_trait :isolated do
              denies :show, :count
            end

            with_bearer_and_token_trait :shared do
              allows :show, :count
            end
          end

          within_environment nil do
            with_bearer_and_token_trait :isolated do
              denies :show, :count
            end

            with_bearer_and_token_trait :shared do
              denies :show, :count
            end
          end
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[accessing_event_logs] do
      with_token_authentication do
        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_an_event_log] do
      with_token_authentication do
        with_wildcard_permissions do
          without_token_permissions { denies :show, :count }

          denies :show, :count
        end

        with_default_permissions do
          without_token_permissions { denies :show, :count }

          denies :show, :count
        end

        without_permissions do
          denies :show, :count
        end
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[accessing_event_logs] do
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

    with_scenarios %i[accessing_an_event_log] do
      with_license_authentication do
        with_wildcard_permissions do
          denies :show, :count
        end

        with_default_permissions do
          denies :show, :count
        end

        without_permissions do
          denies :show, :count
        end
      end

      with_token_authentication do
        with_wildcard_permissions do
          denies :show, :count
        end

        with_default_permissions do
          denies :show, :count
        end

        without_permissions do
          denies :show, :count
        end
      end
    end
  end

  with_role_authorization :user do
    with_scenarios %i[accessing_event_logs] do
      with_token_authentication do
        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_an_event_log] do
      with_token_authentication do
        with_wildcard_permissions do
          without_token_permissions { denies :show, :count }

          denies :show, :count
        end

        with_default_permissions do
          without_token_permissions { denies :show, :count }

          denies :show, :count
        end

        without_permissions do
          denies :show, :count
        end
      end
    end
  end

  without_authorization do
    with_scenarios %i[accessing_event_logs] do
      without_authentication { denies :index }
    end

    with_scenarios %i[accessing_an_event_log] do
      without_authentication { denies :show, :count }
    end
  end
end
