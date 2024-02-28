# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Releases::V1x0::YankPolicy, type: :policy do
  subject { described_class.new(record, account:, environment:, bearer:, token:, release:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_a_release] do
      with_token_authentication do
        with_permissions %w[release.yank] do
          without_token_permissions { denies :yank }

          allows :yank
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :yank
          end

          allows :yank
        end

        with_default_permissions do
          without_token_permissions do
            denies :yank
          end

          allows :yank
        end

        without_permissions do
          denies :yank
        end

        within_environment :isolated do
          with_bearer_and_token_trait :in_shared_environment do
            denies :yank
          end

          with_bearer_and_token_trait :in_nil_environment do
            denies :yank
          end

          allows :yank
        end

        within_environment :shared do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :yank
          end

          with_bearer_and_token_trait :in_nil_environment do
            allows :yank
          end

          allows :yank
        end

        within_environment nil do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :yank
          end

          with_bearer_and_token_trait :in_shared_environment do
            denies :yank
          end

          allows :yank
        end
      end
    end

    with_scenarios %i[accessing_another_account accessing_a_release] do
      with_token_authentication do
        with_permissions %w[release.yank] do
          denies :yank
        end

        with_wildcard_permissions do
          denies :yank
        end

        with_default_permissions do
          denies :yank
        end

        without_permissions do
          denies :yank
        end
      end
    end
  end

  with_role_authorization :environment do
    within_environment :self do
      with_scenarios %i[accessing_a_release] do
        with_token_authentication do
          with_permissions %w[release.yank] do
            without_token_permissions { denies :yank }

            allows :yank
          end

          with_wildcard_permissions do
            without_token_permissions do
              denies :yank
            end

            allows :yank
          end

          with_default_permissions do
            without_token_permissions do
              denies :yank
            end

            allows :yank
          end

          without_permissions do
            denies :yank
          end
        end
      end
    end

    with_scenarios %i[accessing_a_release] do
      with_token_authentication do
        with_permissions %w[release.yank] do
          denies :yank
        end

        with_wildcard_permissions do
          denies :yank
        end

        with_default_permissions do
          denies :yank
        end

        without_permissions do
          denies :yank
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[accessing_its_release] do
      with_token_authentication do
        with_permissions %w[release.yank] do
          without_token_permissions { denies :yank }

          allows :yank
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :yank
          end

          allows :yank
        end

        with_default_permissions do
          without_token_permissions do
            denies :yank
          end

          allows :yank
        end

        without_permissions do
          denies :yank
        end
      end
    end

    with_scenarios %i[accessing_a_release] do
      with_token_authentication do
        with_permissions %w[release.yank] do
          denies :yank
        end

        with_wildcard_permissions do
          denies :yank
        end

        with_default_permissions do
          denies :yank
        end

        without_permissions do
          denies :yank
        end
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[accessing_its_release] do
      with_license_authentication do
        with_wildcard_permissions do
          denies :yank
        end

        with_default_permissions do
          denies :yank
        end

        without_permissions do
          denies :yank
        end
      end

      with_token_authentication do
        with_wildcard_permissions do
          without_token_permissions do
            denies :yank
          end

          denies :yank
        end

        with_default_permissions do
          without_token_permissions do
            denies :yank
          end

          denies :yank
        end

        without_permissions do
          denies :yank
        end
      end
    end

    with_scenarios %i[accessing_a_release] do
      with_license_authentication do
        with_wildcard_permissions do
          denies :yank
        end

        with_default_permissions do
          denies :yank
        end

        without_permissions do
          denies :yank
        end
      end

      with_token_authentication do
        with_wildcard_permissions do
          denies :yank
        end

        with_default_permissions do
          denies :yank
        end

        without_permissions do
          denies :yank
        end
      end
    end
  end

  with_role_authorization :user do
    with_bearer_trait :with_licenses do
      with_scenarios %i[accessing_its_release] do
        with_token_authentication do
          with_wildcard_permissions do
            without_token_permissions do
              denies :yank
            end

            denies :yank
          end

          with_default_permissions do
            without_token_permissions do
              denies :yank
            end

            denies :yank
          end

          without_permissions do
            denies :yank
          end
        end
      end
    end

    with_scenarios %i[accessing_a_release] do
      with_token_authentication do
        with_wildcard_permissions do
          denies :yank
        end

        with_default_permissions do
          denies :yank
        end

        without_permissions do
          denies :yank
        end
      end
    end
  end

  without_authorization do
    with_scenarios %i[accessing_a_release] do
      without_authentication do
        denies :yank
      end
    end
  end
end
