# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe ProductPolicy, type: :policy do
  subject { described_class.new(context, resource) }

  with_role_authorization :admin do
    with_scenarios %i[as_admin accessing_products] do
      with_token_authentication do
        with_permissions %w[product.read] do
          without_token_permissions { forbids :index }

          permits :index
        end

        with_wildcard_permissions { permits :index }
        with_default_permissions  { permits :index }
        without_permissions       { forbids :index }
      end
    end

    with_scenarios %i[as_admin accessing_a_product] do
      with_token_authentication do
        with_permissions %w[product.read] do
          without_token_permissions { forbids :show }

          permits :show
        end

        with_permissions %w[product.create] do
          without_token_permissions { forbids :create }

          permits :create
        end

        with_permissions %w[product.update] do
          without_token_permissions { forbids :update }

          permits :update
        end

        with_permissions %w[product.delete] do
          without_token_permissions { forbids :destroy }

          permits :destroy
        end

        with_wildcard_permissions do
          without_token_permissions do
            forbids :show
            forbids :create
            forbids :update
            forbids :destroy
          end

          permits :show
          permits :create
          permits :update
          permits :destroy
        end

        with_default_permissions do
          without_token_permissions do
            forbids :show
            forbids :create
            forbids :update
            forbids :destroy
          end

          permits :show
          permits :create
          permits :update
          permits :destroy
        end

        without_permissions do
          with_token_permissions %w[product.read product.create product.update product.delete] do
            forbids :show
            forbids :create
            forbids :update
            forbids :destroy
          end

          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end
      end
    end

    with_scenarios %i[as_admin accessing_another_account accessing_products] do
      with_token_authentication do
        with_permissions %w[product.read] do
          forbids :index
        end

        with_wildcard_permissions { forbids :index }
        with_default_permissions  { forbids :index }
        without_permissions       { forbids :index }
      end
    end

    with_scenarios %i[as_admin accessing_another_account accessing_a_product] do
      with_token_authentication do
        with_permissions %w[product.read] do
          forbids :show
        end

        with_permissions %w[product.create] do
          forbids :create
        end

        with_permissions %w[product.update] do
          forbids :update
        end

        with_permissions %w[product.delete] do
          forbids :destroy
        end

        with_wildcard_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end

        with_default_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end

        without_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[as_product accessing_products] do
      with_token_authentication do
        with_permissions %w[product.read] do
          forbids :index
        end

        with_wildcard_permissions { forbids :index }
        with_default_permissions  { forbids :index }
        without_permissions       { forbids :index }
      end
    end

    with_scenarios %i[as_product accessing_itself] do
      with_token_authentication do
        with_permissions %w[product.read] do
          permits :show
        end

        with_permissions %w[product.create] do
          forbids :create
        end

        with_permissions %w[product.update] do
          permits :update
        end

        with_permissions %w[product.delete] do
          forbids :destroy
        end

        with_wildcard_permissions do
          permits :show
          forbids :create
          permits :update
          forbids :destroy
        end

        with_default_permissions do
          permits :show
          forbids :create
          permits :update
          forbids :destroy
        end

        without_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end
      end
    end

    with_scenarios %i[as_product accessing_another_product] do
      with_token_authentication do
        with_permissions %w[product.read] do
          forbids :show
        end

        with_permissions %w[product.create] do
          forbids :create
        end

        with_permissions %w[product.update] do
          forbids :update
        end

        with_permissions %w[product.delete] do
          forbids :destroy
        end

        with_wildcard_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end

        with_default_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end

        without_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[as_license accessing_its_products] do
      with_license_authentication do
        with_permissions %w[product.read] do
          permits :index
        end

        with_wildcard_permissions { permits :index }
        with_default_permissions  { forbids :index }
        without_permissions       { forbids :index }
      end

      with_token_authentication do
        with_permissions %w[product.read] do
          permits :index
        end

        with_wildcard_permissions { permits :index }
        with_default_permissions  { forbids :index }
        without_permissions       { forbids :index }
      end
    end

    with_scenarios %i[as_license accessing_its_product] do
      with_license_authentication do
        with_permissions %w[product.read] do
          permits :show
        end

        with_wildcard_permissions do
          permits :show
          forbids :create
          forbids :update
          forbids :destroy
        end

        with_default_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end

        without_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end
      end

      with_token_authentication do
        with_permissions %w[product.read] do
          permits :show
        end

        with_wildcard_permissions do
          permits :show
          forbids :create
          forbids :update
          forbids :destroy
        end

        with_default_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end

        without_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end
      end
    end

    with_scenarios %i[as_license accessing_other_products] do
      with_license_authentication do
        with_permissions %w[product.read] do
          forbids :index
        end

        with_wildcard_permissions { forbids :index }
        with_default_permissions  { forbids :index }
        without_permissions       { forbids :index }
      end

      with_token_authentication do
        with_permissions %w[product.read] do
          forbids :index
        end

        with_wildcard_permissions { forbids :index }
        with_default_permissions  { forbids :index }
        without_permissions       { forbids :index }
      end
    end

    with_scenarios %i[as_license accessing_another_product] do
      with_license_authentication do
        with_permissions %w[product.read] do
          forbids :show
        end

        with_wildcard_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end

        with_default_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end

        without_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end
      end

      with_token_authentication do
        with_permissions %w[product.read] do
          forbids :show
        end

        with_wildcard_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end

        with_default_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end

        without_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end
      end
    end
  end

  with_role_authorization :user do
    with_scenarios %i[as_user with_licenses accessing_their_products] do
      with_token_authentication do
        with_permissions %w[product.read] do
          permits :index
        end

        with_wildcard_permissions { permits :index }
        with_default_permissions  { forbids :index }
        without_permissions       { forbids :index }
      end
    end

    with_scenarios %i[as_user with_licenses accessing_their_product] do
      with_token_authentication do
        with_permissions %w[product.read] do
          permits :show
        end

        with_wildcard_permissions do
          permits :show
          forbids :create
          forbids :update
          forbids :destroy
        end

        with_default_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end

        without_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end
      end
    end

    with_scenarios %i[as_user with_licenses accessing_other_products] do
      with_token_authentication do
        with_permissions %w[product.read] do
          forbids :index
        end

        with_wildcard_permissions { forbids :index }
        with_default_permissions  { forbids :index }
        without_permissions       { forbids :index }
      end
    end

    with_scenarios %i[as_user with_licenses accessing_another_product] do
      with_token_authentication do
        with_permissions %w[product.read] do
          forbids :show
        end

        with_wildcard_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end

        with_default_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end

        without_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end
      end
    end

    with_scenarios %i[as_user accessing_products] do
      with_token_authentication do
        with_permissions %w[product.read] do
          forbids :index
        end

        with_wildcard_permissions { forbids :index }
        with_default_permissions  { forbids :index }
        without_permissions       { forbids :index }
      end
    end

    with_scenarios %i[as_user accessing_a_product] do
      with_token_authentication do
        with_permissions %w[product.read] do
          forbids :show
        end

        with_wildcard_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end

        with_default_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end

        without_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end
      end
    end
  end

  without_authorization do
    with_scenarios %i[as_anonymous accessing_products] do
      without_authentication do
        with_permissions %w[product.read] do
          forbids :index
        end

        with_wildcard_permissions { forbids :index }
        with_default_permissions  { forbids :index }
        without_permissions       { forbids :index }
      end
    end

    with_scenarios %i[as_anonymous accessing_a_product] do
      without_authentication do
        with_permissions %w[product.read] do
          forbids :show
        end

        with_wildcard_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end

        with_default_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end

        without_permissions do
          forbids :show
          forbids :create
          forbids :update
          forbids :destroy
        end
      end
    end
  end
end
