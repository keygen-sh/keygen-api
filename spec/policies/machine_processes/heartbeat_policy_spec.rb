# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe MachineProcesses::HeartbeatPolicy, type: :policy do
  subject { described_class.new(record, account:, environment:, bearer:, token:, machine_process:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_a_machine_process] do
      with_token_authentication do
        with_permissions %w[process.heartbeat.ping] do
          without_token_permissions { denies :ping }

          allows :ping
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :ping
          end

          allows :ping
        end

        with_default_permissions do
          without_token_permissions do
            denies :ping
          end

          allows :ping
        end

        without_permissions do
          denies :ping
        end

        within_environment :isolated do
          with_bearer_and_token_trait :in_shared_environment do
            denies :ping
          end

          with_bearer_and_token_trait :in_nil_environment do
            denies :ping
          end

          allows :ping
        end

        within_environment :shared do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :ping
          end

          with_bearer_and_token_trait :in_nil_environment do
            allows :ping
          end

          allows :ping
        end

        within_environment nil do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :ping
          end

          with_bearer_and_token_trait :in_shared_environment do
            denies :ping
          end

          allows :ping
        end
      end
    end

    with_scenarios %i[accessing_another_account accessing_a_machine_process] do
      with_token_authentication do
        with_permissions %w[process.heartbeat.ping] do
          denies :ping
        end

        with_wildcard_permissions do
          denies :ping
        end

        with_default_permissions do
          denies :ping
        end

        without_permissions do
          denies :ping
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[accessing_its_machine_process] do
      with_token_authentication do
        with_permissions %w[process.heartbeat.ping] do
          without_token_permissions { denies :ping }

          allows :ping
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :ping
          end

          allows :ping
        end

        with_default_permissions do
          without_token_permissions do
            denies :ping
          end

          allows :ping
        end

        without_permissions do
          denies :ping
        end
      end
    end

    with_scenarios %i[accessing_a_machine_process] do
      with_token_authentication do
        with_permissions %w[process.heartbeat.ping] do
          denies :ping
        end

        with_wildcard_permissions do
          denies :ping
        end

        with_default_permissions do
          denies :ping
        end

        without_permissions do
          denies :ping
        end
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[accessing_its_machine_process] do
      with_license_authentication do
        with_permissions %w[process.heartbeat.ping] do
          allows :ping
        end

        with_wildcard_permissions do
          allows :ping
        end

        with_default_permissions do
          allows :ping
        end

        without_permissions do
          denies :ping
        end
      end

      with_token_authentication do
        with_permissions %w[process.heartbeat.ping] do
          without_token_permissions { denies :ping }

          allows :ping
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :ping
          end

          allows :ping
        end

        with_default_permissions do
          without_token_permissions do
            denies :ping
          end

          allows :ping
        end

        without_permissions do
          denies :ping
        end
      end
    end

    with_scenarios %i[accessing_a_machine_process] do
      with_license_authentication do
        with_permissions %w[process.heartbeat.ping] do
          denies :ping
        end

        with_wildcard_permissions do
          denies :ping
        end

        with_default_permissions do
          denies :ping
        end

        without_permissions do
          denies :ping
        end
      end

      with_token_authentication do
        with_permissions %w[process.heartbeat.ping] do
          denies :ping
        end

        with_wildcard_permissions do
          denies :ping
        end

        with_default_permissions do
          denies :ping
        end

        without_permissions do
          denies :ping
        end
      end
    end
  end

  with_role_authorization :user do
    with_bearer_trait :with_licenses do
      with_scenarios %i[accessing_its_machine_process] do
        with_token_authentication do
          with_permissions %w[process.heartbeat.ping] do
            without_token_permissions { denies :ping }

            allows :ping
          end

          with_wildcard_permissions do
            without_token_permissions do
              denies :ping
            end

            allows :ping
          end

          with_default_permissions do
            without_token_permissions do
              denies :ping
            end

            allows :ping
          end

          without_permissions do
            denies :ping
          end
        end
      end
    end

    with_scenarios %i[accessing_a_machine_process] do
      with_token_authentication do
        with_permissions %w[process.heartbeat.ping] do
          denies :ping
        end

        with_wildcard_permissions do
          denies :ping
        end

        with_default_permissions do
          denies :ping
        end

        without_permissions do
          denies :ping
        end
      end
    end
  end

  without_authorization do
    with_scenarios %i[accessing_a_machine_process] do
      without_authentication do
        denies :ping
      end
    end
  end
end
