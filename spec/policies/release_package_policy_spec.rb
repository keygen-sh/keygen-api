# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe ReleasePackagePolicy, type: :policy do
  subject { described_class.new(record, account:, environment:, bearer:, token:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_packages] do
      with_token_authentication do
        with_permissions %w[package.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_package] do
      with_token_authentication do
        with_permissions %w[package.create] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_permissions %w[package.delete] do
          without_token_permissions { denies :destroy }

          allows :destroy
        end

        with_permissions %w[package.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[package.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_wildcard_permissions do
          allows :create, :destroy, :show, :update
        end

        with_default_permissions do
          allows :create, :destroy, :show, :update
        end

        without_permissions do
          denies :create, :destroy, :show, :update
        end
      end
    end
  end

  with_role_authorization :environment do
    within_environment :self do
      with_scenarios %i[accessing_packages] do
        with_token_authentication do
          with_permissions %w[package.read] do
            without_token_permissions { denies :index }

            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_package] do
        with_token_authentication do
          with_permissions %w[package.create] do
            without_token_permissions { denies :create }

            allows :create
          end

          with_permissions %w[package.delete] do
            without_token_permissions { denies :destroy }

            allows :destroy
          end

          with_permissions %w[package.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_permissions %w[package.update] do
            without_token_permissions { denies :update }

            allows :update
          end

          with_wildcard_permissions do
            allows :create, :destroy, :show, :update
          end

          with_default_permissions do
            allows :create, :destroy, :show, :update
          end

          without_permissions do
            denies :create, :destroy, :show, :update
          end
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[accessing_its_packages] do
      with_token_authentication do
        with_permissions %w[package.read] do
          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_its_package] do
      with_token_authentication do
        with_permissions %w[package.create] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_permissions %w[package.delete] do
          without_token_permissions { denies :destroy }

          allows :destroy
        end

        with_permissions %w[package.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[package.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_wildcard_permissions do
          allows :create, :destroy, :show, :update
        end

        with_default_permissions do
          allows :create, :destroy, :show, :update
        end

        without_permissions do
          denies :create, :destroy, :show, :update
        end
      end
    end

    with_scenarios %i[accessing_packages] do
      with_token_authentication do
        with_permissions %w[package.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_package] do
      with_token_authentication do
        with_permissions %w[package.create] do
          denies :create
        end

        with_permissions %w[package.delete] do
          denies :destroy
        end

        with_permissions %w[package.read] do
          denies :show
        end

        with_permissions %w[package.update] do
          denies :update
        end

        with_wildcard_permissions do
          denies :create, :destroy, :show, :update
        end

        with_default_permissions do
          denies :create, :destroy, :show, :update
        end

        without_permissions do
          denies :create, :destroy, :show, :update
        end
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[accessing_its_packages] do
      with_license_authentication do
        with_permissions %w[package.read] do
          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end

      with_token_authentication do
        with_permissions %w[package.read] do
          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_its_package] do
      with_license_authentication do
        with_permissions %w[package.read] do
          allows :show
        end

        with_wildcard_permissions do
          denies :create, :destroy, :update
          allows :show
        end

        with_default_permissions do
          denies :create, :destroy, :update
          allows :show
        end

        without_permissions do
          denies :create, :destroy, :show, :update
        end
      end

      with_token_authentication do
        with_permissions %w[package.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_wildcard_permissions do
          denies :create, :destroy, :update
          allows :show
        end

        with_default_permissions do
          denies :create, :destroy, :update
          allows :show
        end

        without_permissions do
          denies :create, :destroy, :show, :update
        end
      end
    end

    with_scenarios %i[accessing_packages] do
      with_package_traits %i[open] do
        with_license_authentication do
          with_permissions %w[package.read] do
            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }
        end

        with_token_authentication do
          with_permissions %w[package.read] do
            without_token_permissions { denies :show }

            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }
        end
      end

      with_license_authentication do
        with_permissions %w[package.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end

      with_token_authentication do
        with_permissions %w[package.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_package] do
      with_package_traits %i[open] do
        with_license_authentication do
          with_permissions %w[package.read] do
            allows :show
          end

          with_wildcard_permissions do
            denies :create, :destroy, :update
            allows :show
          end

          with_default_permissions do
            denies :create, :destroy, :update
            allows :show
          end

          without_permissions do
            denies :create, :destroy, :show, :update
          end
        end

        with_token_authentication do
          with_permissions %w[package.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_wildcard_permissions do
            denies :create, :destroy, :update
            allows :show
          end

          with_default_permissions do
            denies :create, :destroy, :update
            allows :show
          end

          without_permissions do
            denies :create, :destroy, :show, :update
          end
        end
      end

      with_license_authentication do
        with_permissions %w[package.read] do
          denies :show
        end

        with_wildcard_permissions do
          denies :create, :destroy, :show, :update
        end

        with_default_permissions do
          denies :create, :destroy, :show, :update
        end

        without_permissions do
          denies :create, :destroy, :show, :update
        end
      end

      with_token_authentication do
        with_permissions %w[package.read] do
          denies :show
        end

        with_wildcard_permissions do
          denies :create, :destroy, :show, :update
        end

        with_default_permissions do
          denies :create, :destroy, :show, :update
        end

        without_permissions do
          denies :create, :destroy, :show, :update
        end
      end
    end
  end

  with_role_authorization :user do
    with_bearer_trait :with_licenses do
      with_scenarios %i[accessing_its_packages] do
        with_token_authentication do
          with_permissions %w[package.read] do
            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_its_package] do
        with_token_authentication do
          with_permissions %w[package.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_wildcard_permissions do
            denies :create, :destroy, :update
            allows :show
          end

          with_default_permissions do
            denies :create, :destroy, :update
            allows :show
          end

          without_permissions do
            denies :create, :destroy, :show, :update
          end
        end
      end

      with_scenarios %i[accessing_packages] do
        with_package_traits %i[open] do
          with_token_authentication do
            with_permissions %w[package.read] do
              allows :index
            end

            with_wildcard_permissions { allows :index }
            with_default_permissions  { allows :index }
            without_permissions       { denies :index }
          end
        end

        with_token_authentication do
          with_permissions %w[package.read] do
            denies :index
          end

          with_wildcard_permissions { denies :index }
          with_default_permissions  { denies :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_package] do
        with_package_traits %i[open] do
          with_token_authentication do
            with_permissions %w[package.read] do
              without_token_permissions { denies :show }

              allows :show
            end

            with_wildcard_permissions do
              denies :create, :destroy, :update
              allows :show
            end

            with_default_permissions do
              denies :create, :destroy, :update
              allows :show
            end

            without_permissions do
              denies :create, :destroy, :show, :update
            end
          end
        end

        with_token_authentication do
          with_permissions %w[package.read] do
            denies :show
          end

          with_wildcard_permissions do
            denies :create, :destroy, :show, :update
          end

          with_default_permissions do
            denies :create, :destroy, :show, :update
          end

          without_permissions do
            denies :create, :destroy, :show, :update
          end
        end
      end
    end
  end

  without_authorization do
    with_scenarios %i[accessing_packages] do
      without_authentication do
        with_package_traits %i[open] do
          allows :index
        end

        denies :index
      end
    end

    with_scenarios %i[accessing_package] do
      without_authentication do
        with_package_traits %i[open] do
          denies :create, :destroy, :update
          allows :show
        end

        denies :create, :destroy, :show, :update
      end
    end
  end
end
