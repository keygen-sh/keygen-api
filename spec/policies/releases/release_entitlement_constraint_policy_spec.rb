# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Releases::ReleaseEntitlementConstraintPolicy, type: :policy do
  subject { described_class.new(record, account:, environment:, bearer:, token:, release:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_a_release accessing_its_constraints] do
      with_token_authentication do
        with_permissions %w[constraint.read] do
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

    with_scenarios %i[accessing_a_release accessing_its_constraint] do
      with_token_authentication do
        with_permissions %w[constraint.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[release.constraints.attach] do
          without_token_permissions { denies :attach }

          allows :attach
        end

        with_permissions %w[release.constraints.detach] do
          without_token_permissions { denies :detach }

          allows :detach
        end

        with_wildcard_permissions do
          without_token_permissions { denies :show, :attach, :detach }

          allows :show, :attach, :detach
        end

        with_default_permissions do
          without_token_permissions { denies :show, :attach, :detach }

          allows :show, :attach, :detach
        end

        without_permissions do
          denies :show, :attach, :detach
        end

        within_environment :isolated do
          with_bearer_and_token_trait :in_shared_environment do
            denies :show, :attach, :detach
          end

          with_bearer_and_token_trait :in_nil_environment do
            denies :show, :attach, :detach
          end

          allows :show, :attach, :detach
        end

        within_environment :shared do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :show, :attach, :detach
          end

          with_bearer_and_token_trait :in_nil_environment do
            allows :show, :attach, :detach
          end

          allows :show, :attach, :detach
        end

        within_environment nil do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :show, :attach, :detach
          end

          with_bearer_and_token_trait :in_shared_environment do
            denies :show, :attach, :detach
          end

          allows :show, :attach, :detach
        end
      end
    end
  end

  with_role_authorization :environment do
    within_environment :self do
      with_scenarios %i[accessing_a_release accessing_its_constraints] do
        with_token_authentication do
          with_permissions %w[constraint.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_a_release accessing_its_constraint] do
        with_token_authentication do
          with_permissions %w[constraint.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_permissions %w[release.constraints.attach] do
            without_token_permissions { denies :attach }

            allows :attach
          end

          with_permissions %w[release.constraints.detach] do
            without_token_permissions { denies :detach }

            allows :detach
          end

          with_wildcard_permissions do
            without_token_permissions { denies :show, :attach, :detach }

            allows :show, :attach, :detach
          end

          with_default_permissions do
            without_token_permissions { denies :show, :attach, :detach }

            allows :show, :attach, :detach
          end

          without_permissions do
            denies :show, :attach, :detach
          end
        end
      end
    end

    with_scenarios %i[accessing_a_release accessing_its_constraints] do
      with_token_authentication do
        with_permissions %w[constraint.read] do
          denies :show
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_release accessing_its_constraint] do
      with_token_authentication do
        with_permissions %w[constraint.read] do
          denies :show
        end

        with_permissions %w[release.constraints.attach] do
          denies :attach
        end

        with_permissions %w[release.constraints.detach] do
          denies :detach
        end

        with_wildcard_permissions do
          denies :show, :attach, :detach
        end

        with_default_permissions do
          denies :show, :attach, :detach
        end

        without_permissions do
          denies :show, :attach, :detach
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[accessing_its_release accessing_its_constraints] do
      with_token_authentication do
        with_permissions %w[constraint.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_its_release accessing_its_constraint] do
      with_token_authentication do
        with_permissions %w[constraint.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[release.constraints.attach] do
          without_token_permissions { denies :attach }

          allows :attach
        end

        with_permissions %w[release.constraints.detach] do
          without_token_permissions { denies :detach }

          allows :detach
        end

        with_wildcard_permissions do
          without_token_permissions { denies :show, :attach, :detach }

          allows :show, :attach, :detach
        end

        with_default_permissions do
          without_token_permissions { denies :show, :attach, :detach }

          allows :show, :attach, :detach
        end

        without_permissions do
          denies :show, :attach, :detach
        end
      end
    end

    with_scenarios %i[accessing_a_release accessing_its_constraints] do
      with_token_authentication do
        with_permissions %w[constraint.read] do
          denies :show
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_release accessing_its_constraint] do
      with_token_authentication do
        with_permissions %w[constraint.read] do
          denies :show
        end

        with_permissions %w[release.constraints.attach] do
          denies :attach
        end

        with_permissions %w[release.constraints.detach] do
          denies :detach
        end

        with_wildcard_permissions do
          denies :show, :attach, :detach
        end

        with_default_permissions do
          denies :show, :attach, :detach
        end

        without_permissions do
          denies :show, :attach, :detach
        end
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[accessing_its_release accessing_its_constraints] do
      with_license_authentication do
        with_permissions %w[constraint.read] do
          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end

      with_token_authentication do
        with_permissions %w[constraint.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_wildcard_permissions do
          without_token_permissions { denies :index }

          allows :index
        end

        with_default_permissions do
          without_token_permissions { denies :index }

          allows :index
        end

        without_permissions { denies :index }
      end
    end

    with_scenarios %i[accessing_its_release accessing_its_constraint] do
      with_license_authentication do
        with_permissions %w[constraint.read] do
          allows :show
        end

        with_wildcard_permissions do
          denies :attach, :detach
          allows :show
        end

        with_default_permissions do
          denies :attach, :detach
          allows :show
        end

        without_permissions { denies :show, :attach, :detach }
      end

      with_token_authentication do
        with_permissions %w[constraint.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_wildcard_permissions do
          without_token_permissions { denies :show, :attach, :detach }

          denies :attach, :detach
          allows :show
        end

        with_default_permissions do
          without_token_permissions { denies :show, :attach, :detach }

          denies :attach, :detach
          allows :show
        end

        without_permissions { denies :show, :attach, :detach }
      end
    end

    with_scenarios %i[accessing_a_release accessing_its_constraints] do
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

    with_scenarios %i[accessing_a_release accessing_its_constraint] do
      with_license_authentication do
        with_wildcard_permissions { denies :show, :attach, :detach }
        with_default_permissions  { denies :show, :attach, :detach }
        without_permissions       { denies :show, :attach, :detach }
      end

      with_token_authentication do
        with_wildcard_permissions { denies :show, :attach, :detach }
        with_default_permissions  { denies :show, :attach, :detach }
        without_permissions       { denies :show, :attach, :detach }
      end
    end
  end

  with_role_authorization :user do
    with_bearer_trait :with_owned_licenses do
      with_scenarios %i[accessing_its_release accessing_its_constraints] do
        with_token_authentication do
          with_permissions %w[constraint.read] do
            without_token_permissions { denies :index }

            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_its_release accessing_its_constraint] do
        with_token_authentication do
          with_permissions %w[constraint.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_wildcard_permissions do
            without_token_permissions { denies :show, :attach, :detach }

            denies :attach, :detach
            allows :show
          end

          with_default_permissions do
            without_token_permissions { denies :show, :attach, :detach }

            denies :attach, :detach
            allows :show
          end

          without_permissions { denies :show, :attach, :detach }
        end
      end
    end

    with_bearer_trait :with_user_licenses do
      with_scenarios %i[accessing_its_release accessing_its_constraints] do
        with_token_authentication do
          with_permissions %w[constraint.read] do
            without_token_permissions { denies :index }

            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_its_release accessing_its_constraint] do
        with_token_authentication do
          with_permissions %w[constraint.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_wildcard_permissions do
            without_token_permissions { denies :show, :attach, :detach }

            denies :attach, :detach
            allows :show
          end

          with_default_permissions do
            without_token_permissions { denies :show, :attach, :detach }

            denies :attach, :detach
            allows :show
          end

          without_permissions { denies :show, :attach, :detach }
        end
      end
    end

    with_scenarios %i[accessing_a_release accessing_its_constraints] do
      with_token_authentication do
        with_permissions %w[constraint.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_release accessing_its_constraint] do
      with_token_authentication do
        with_wildcard_permissions { denies :show, :attach, :detach }
        with_default_permissions  { denies :show, :attach, :detach }
        without_permissions       { denies :show, :attach, :detach }
      end
    end
  end

  without_authorization do
    with_scenarios %i[accessing_a_release accessing_its_constraints] do
      without_authentication { denies :index }
    end

    with_scenarios %i[accessing_a_release accessing_its_constraint] do
      without_authentication { denies :show, :attach, :detach }
    end
  end
end
