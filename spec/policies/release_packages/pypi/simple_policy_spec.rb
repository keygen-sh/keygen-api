# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe ReleasePackages::Pypi::SimplePolicy, type: :policy do
  subject { described_class.new(record, account:, environment:, bearer:, token:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_products] do
      with_token_authentication do
        with_permissions %w[artifact.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_artifacts] do
      with_token_authentication do
        with_permissions %w[artifact.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_wildcard_permissions { allows :show }
        with_default_permissions  { allows :show }
        without_permissions       { denies :show }
      end
    end
  end

  with_role_authorization :environment do
    within_environment :self do
      with_scenarios %i[accessing_products] do
        with_token_authentication do
          with_permissions %w[artifact.read] do
            without_token_permissions { denies :index }

            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_artifacts] do
        with_token_authentication do
          with_permissions %w[artifact.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_wildcard_permissions { allows :show }
          with_default_permissions  { allows :show }
          without_permissions       { denies :show }
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[accessing_its_products] do
      with_token_authentication do
        with_permissions %w[artifact.read] do
          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_products] do
      with_token_authentication do
        with_permissions %w[artifact.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_its_artifacts] do
      with_token_authentication do
        with_permissions %w[artifact.read] do
          allows :show
        end

        with_wildcard_permissions { allows :show }
        with_default_permissions  { allows :show }
        without_permissions       { denies :show }
      end
    end

    with_scenarios %i[accessing_artifacts] do
      with_token_authentication do
        with_permissions %w[artifact.read] do
          denies :show
        end

        with_wildcard_permissions { denies :show }
        with_default_permissions  { denies :show }
        without_permissions       { denies :show }
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[accessing_its_products] do
      with_license_authentication do
        with_permissions %w[artifact.read] do
          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end

      with_token_authentication do
        with_permissions %w[artifact.read] do
          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_products] do
      with_product_traits %i[open] do
        with_license_authentication do
          with_permissions %w[artifact.read] do
            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }
        end

        with_token_authentication do
          with_permissions %w[artifact.read] do
            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }
        end
      end

      with_license_authentication do
        with_permissions %w[artifact.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end

      with_token_authentication do
        with_permissions %w[artifact.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_its_artifacts] do
      with_license_authentication do
        with_permissions %w[artifact.read] do
          allows :show
        end

        with_wildcard_permissions { allows :show }
        with_default_permissions  { allows :show }
        without_permissions       { denies :show }
      end

      with_token_authentication do
        with_permissions %w[artifact.read] do
          allows :show
        end

        with_wildcard_permissions { allows :show }
        with_default_permissions  { allows :show }
        without_permissions       { denies :show }
      end
    end

    with_scenarios %i[accessing_artifacts] do
      with_artifact_traits %i[open] do
        with_license_authentication do
          with_permissions %w[artifact.read] do
            allows :show
          end

          with_wildcard_permissions { allows :show }
          with_default_permissions  { allows :show }
          without_permissions       { denies :show }
        end

        with_token_authentication do
          with_permissions %w[artifact.read] do
            allows :show
          end

          with_wildcard_permissions { allows :show }
          with_default_permissions  { allows :show }
          without_permissions       { denies :show }
        end
      end

      with_license_authentication do
        with_permissions %w[artifact.read] do
          denies :show
        end

        with_wildcard_permissions { denies :show }
        with_default_permissions  { denies :show }
        without_permissions       { denies :show }
      end

      with_token_authentication do
        with_permissions %w[artifact.read] do
          denies :show
        end

        with_wildcard_permissions { denies :show }
        with_default_permissions  { denies :show }
        without_permissions       { denies :show }
      end
    end
  end

  with_role_authorization :user do
    with_bearer_trait :with_licenses do
      with_scenarios %i[accessing_its_products] do
        with_token_authentication do
          with_permissions %w[artifact.read] do
            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_products] do
        with_product_traits %i[open] do
          with_token_authentication do
            with_permissions %w[artifact.read] do
              allows :index
            end

            with_wildcard_permissions { allows :index }
            with_default_permissions  { allows :index }
            without_permissions       { denies :index }
          end
        end

        with_token_authentication do
          with_permissions %w[artifact.read] do
            denies :index
          end

          with_wildcard_permissions { denies :index }
          with_default_permissions  { denies :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_its_artifacts] do
        with_token_authentication do
          with_permissions %w[artifact.read] do
            allows :show
          end

          with_wildcard_permissions { allows :show }
          with_default_permissions  { allows :show }
          without_permissions       { denies :show }
        end
      end

      with_scenarios %i[accessing_artifacts] do
        with_artifact_traits %i[open] do
          with_token_authentication do
            with_permissions %w[artifact.read] do
              allows :show
            end

            with_wildcard_permissions { allows :show }
            with_default_permissions  { allows :show }
            without_permissions       { denies :show }
          end
        end

        with_token_authentication do
          with_permissions %w[artifact.read] do
            denies :show
          end

          with_wildcard_permissions { denies :show }
          with_default_permissions  { denies :show }
          without_permissions       { denies :show }
        end
      end
    end
  end

  without_authorization do
    with_scenarios %i[accessing_products] do
      without_authentication do
        with_product_traits %i[open] do
          allows :index
        end

        denies :index
      end
    end

    with_scenarios %i[accessing_artifacts] do
      without_authentication do
        with_artifact_traits %i[open] do
          allows :show
        end

        denies :show
      end
    end
  end
end
