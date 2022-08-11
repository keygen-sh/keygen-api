# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe License::GroupPolicy, type: :policy do
  subject { described_class.new(context, resource) }

  with_role_authorization :admin do
    with_scenarios %i[as_admin accessing_a_license accessing_its_group] do
      with_token_authentication do
        with_permissions %w[license.group.read] do
          without_token_permissions { forbids :show }

          permits :show
        end

        with_permissions %w[license.group.update] do
          without_token_permissions { forbids :update }

          permits :update
        end

        with_wildcard_permissions do
          without_token_permissions do
            forbids :show, :update
          end

          permits :show, :update
        end

        with_default_permissions do
          without_token_permissions do
            forbids :show, :update
          end

          permits :show, :update
        end

        without_permissions do
          forbids :show, :update
        end
      end
    end

    with_scenarios %i[as_admin accessing_another_account accessing_a_license accessing_its_group] do
      with_token_authentication do
        with_permissions %w[license.group.read] do
          forbids :show
        end

        with_permissions %w[license.group.update] do
          forbids :update
        end

        with_wildcard_permissions do
          forbids :show, :update
        end

        with_default_permissions do
          forbids :show, :update
        end

        without_permissions do
          forbids :show, :update
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[as_product accessing_its_license accessing_its_group] do
      with_token_authentication do
        with_permissions %w[license.group.read] do
          without_token_permissions { forbids :show }

          permits :show
        end

        with_permissions %w[license.group.update] do
          without_token_permissions { forbids :update }

          permits :update
        end

        with_wildcard_permissions do
          permits :show, :update
        end

        with_default_permissions do
          permits :show, :update
        end

        without_permissions do
          forbids :show, :update
        end
      end
    end

    with_scenarios %i[as_product accessing_a_license accessing_its_group] do
      with_token_authentication do
        with_permissions %w[license.group.read] do
          without_token_permissions { forbids :show }

          forbids :show
        end

        with_permissions %w[license.group.update] do
          without_token_permissions { forbids :update }

          forbids :update
        end

        with_wildcard_permissions do
          forbids :show, :update
        end

        with_default_permissions do
          forbids :show, :update
        end

        without_permissions do
          forbids :show, :update
        end
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[as_license accessing_itself accessing_its_group] do
      with_license_authentication do
        with_permissions %w[license.group.read] do
          permits :show
        end

        with_wildcard_permissions do
          forbids :update
          permits :show
        end

        with_default_permissions do
          forbids :update
          permits :show
        end

        without_permissions do
          forbids :update
          forbids :show
        end
      end

      with_token_authentication do
        with_permissions %w[license.group.read] do
          without_token_permissions { forbids :show }

          permits :show
        end

        with_wildcard_permissions do
          forbids :update
          permits :show
        end

        with_default_permissions do
          forbids :update
          permits :show
        end

        without_permissions do
          forbids :update
          forbids :show
        end
      end
    end
  end

  with_role_authorization :user do
    with_scenarios %i[as_user with_licenses accessing_its_license accessing_its_group] do
      with_token_authentication do
        with_permissions %w[license.group.read] do
          without_token_permissions { forbids :show }

          permits :show
        end

        with_wildcard_permissions do
          forbids :update
          permits :show
        end

        with_default_permissions do
          forbids :update
          permits :show
        end

        without_permissions do
          forbids :update
          forbids :show
        end
      end
    end
  end

  without_authorization do
    with_scenarios %i[as_anonymous accessing_a_license accessing_its_group] do
      without_authentication do
        forbids :show, :update
      end
    end
  end
end
