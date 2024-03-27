# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Machines::HeartbeatPolicy, type: :policy do
  subject { described_class.new(record, account:, environment:, bearer:, token:, machine:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_a_machine] do
      with_token_authentication do
        with_permissions %w[machine.heartbeat.ping] do
          without_token_permissions { denies :ping }

          allows :ping
        end

        with_permissions %w[machine.heartbeat.reset] do
          without_token_permissions { denies :reset }

          allows :reset
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :ping, :reset
          end

          allows :ping, :reset
        end

        with_default_permissions do
          without_token_permissions do
            denies :ping, :reset
          end

          allows :ping, :reset
        end

        without_permissions do
          denies :ping, :reset
        end

        within_environment :isolated do
          with_bearer_and_token_trait :in_shared_environment do
            denies :ping, :reset
          end

          with_bearer_and_token_trait :in_nil_environment do
            denies :ping, :reset
          end

          allows :ping, :reset
        end

        within_environment :shared do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :ping, :reset
          end

          with_bearer_and_token_trait :in_nil_environment do
            allows :ping, :reset
          end

          allows :ping, :reset
        end

        within_environment nil do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :ping, :reset
          end

          with_bearer_and_token_trait :in_shared_environment do
            denies :ping, :reset
          end

          allows :ping, :reset
        end
      end
    end

    with_scenarios %i[accessing_another_account accessing_a_machine] do
      with_token_authentication do
        with_permissions %w[machine.heartbeat.ping] do
          denies :ping
        end

        with_permissions %w[machine.heartbeat.reset] do
          denies :reset
        end

        with_wildcard_permissions do
          denies :ping, :reset
        end

        with_default_permissions do
          denies :ping, :reset
        end

        without_permissions do
          denies :ping, :reset
        end
      end
    end
  end

  with_role_authorization :environment do
    within_environment :self do
      with_scenarios %i[accessing_a_machine] do
        with_token_authentication do
          with_permissions %w[machine.heartbeat.ping] do
            without_token_permissions { denies :ping }

            allows :ping
          end

          with_permissions %w[machine.heartbeat.reset] do
            without_token_permissions { denies :reset }

            allows :reset
          end

          with_wildcard_permissions do
            without_token_permissions do
              denies :ping, :reset
            end

            allows :ping, :reset
          end

          with_default_permissions do
            without_token_permissions do
              denies :ping, :reset
            end

            allows :ping, :reset
          end

          without_permissions do
            denies :ping, :reset
          end
        end
      end
    end

    with_scenarios %i[accessing_a_machine] do
      with_token_authentication do
        with_permissions %w[machine.heartbeat.ping] do
          denies :ping
        end

        with_permissions %w[machine.heartbeat.reset] do
          denies :reset
        end

        with_wildcard_permissions do
          denies :ping, :reset
        end

        with_default_permissions do
          denies :ping, :reset
        end

        without_permissions do
          denies :ping, :reset
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[accessing_its_machine] do
      with_token_authentication do
        with_permissions %w[machine.heartbeat.ping] do
          without_token_permissions { denies :ping }

          allows :ping
        end

        with_permissions %w[machine.heartbeat.reset] do
          without_token_permissions { denies :reset }

          allows :reset
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :ping, :reset
          end

          allows :ping, :reset
        end

        with_default_permissions do
          without_token_permissions do
            denies :ping, :reset
          end

          allows :ping, :reset
        end

        without_permissions do
          denies :ping, :reset
        end
      end
    end

    with_scenarios %i[accessing_a_machine] do
      with_token_authentication do
        with_permissions %w[machine.heartbeat.ping] do
          denies :ping
        end

        with_permissions %w[machine.heartbeat.reset] do
          denies :reset
        end

        with_wildcard_permissions do
          denies :ping, :reset
        end

        with_default_permissions do
          denies :ping, :reset
        end

        without_permissions do
          denies :ping, :reset
        end
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[accessing_its_machine] do
      with_license_authentication do
        with_permissions %w[machine.heartbeat.ping] do
          allows :ping
        end

        with_wildcard_permissions do
          denies :reset
          allows :ping
        end

        with_default_permissions do
          denies :reset
          allows :ping
        end

        without_permissions do
          denies :ping, :reset
        end
      end

      with_token_authentication do
        with_permissions %w[machine.heartbeat.ping] do
          without_token_permissions { denies :ping }

          allows :ping
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :ping, :reset
          end

          denies :reset
          allows :ping
        end

        with_default_permissions do
          without_token_permissions do
            denies :ping, :reset
          end

          denies :reset
          allows :ping
        end

        without_permissions do
          denies :ping, :reset
        end
      end
    end

    with_scenarios %i[accessing_a_machine] do
      with_license_authentication do
        with_permissions %w[machine.heartbeat.ping] do
          denies :ping
        end

        with_wildcard_permissions do
          denies :ping, :reset
        end

        with_default_permissions do
          denies :ping, :reset
        end

        without_permissions do
          denies :ping, :reset
        end
      end

      with_token_authentication do
        with_permissions %w[machine.heartbeat.ping] do
          denies :ping
        end

        with_wildcard_permissions do
          denies :ping, :reset
        end

        with_default_permissions do
          denies :ping, :reset
        end

        without_permissions do
          denies :ping, :reset
        end
      end
    end
  end

  with_role_authorization :user do
    with_bearer_trait :with_owned_licenses do
      with_scenarios %i[accessing_its_machine] do
        with_token_authentication do
          with_permissions %w[machine.heartbeat.ping] do
            without_token_permissions { denies :ping }

            allows :ping
          end

          with_wildcard_permissions do
            without_token_permissions do
              denies :ping, :reset
            end

            denies :reset
            allows :ping
          end

          with_default_permissions do
            without_token_permissions do
              denies :ping, :reset
            end

            denies :reset
            allows :ping
          end

          without_permissions do
            denies :ping, :reset
          end
        end
      end
    end

    with_bearer_trait :with_user_licenses do
      with_scenarios %i[accessing_its_machine] do
        with_token_authentication do
          with_permissions %w[machine.heartbeat.ping] do
            without_token_permissions { denies :ping }

            allows :ping
          end

          with_wildcard_permissions do
            without_token_permissions do
              denies :ping, :reset
            end

            denies :reset
            allows :ping
          end

          with_default_permissions do
            without_token_permissions do
              denies :ping, :reset
            end

            denies :reset
            allows :ping
          end

          without_permissions do
            denies :ping, :reset
          end
        end
      end

      with_scenarios %i[accessing_our_machine] do
        with_token_authentication do
          with_permissions %w[machine.heartbeat.ping] do
            denies :ping
          end

          with_wildcard_permissions do
            denies :ping, :reset
          end

          with_default_permissions do
            denies :ping, :reset
          end

          without_permissions do
            denies :ping, :reset
          end
        end
      end
    end

    with_scenarios %i[accessing_a_machine] do
      with_token_authentication do
        with_permissions %w[machine.heartbeat.ping] do
          denies :ping
        end

        with_wildcard_permissions do
          denies :ping, :reset
        end

        with_default_permissions do
          denies :ping, :reset
        end

        without_permissions do
          denies :ping, :reset
        end
      end
    end
  end

  without_authorization do
    with_scenarios %i[accessing_a_machine] do
      without_authentication do
        denies :ping, :reset
      end
    end
  end
end
