# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Product::TokenPolicy, type: :policy do
  subject { described_class.new(context, resource) }

  with_role_authorization :admin do
    with_scenarios %i[as_admin accessing_a_product accessing_its_tokens] do
      with_token_authentication do
        with_permissions %w[product.tokens.read] do
          without_token_permissions { forbids :index }

          permits :index
        end

        with_wildcard_permissions { permits :index }
        with_default_permissions  { permits :index }
        without_permissions       { forbids :index }
      end
    end

    with_scenarios %i[as_admin accessing_a_product accessing_its_token] do
      with_token_authentication do
        with_permissions %w[product.tokens.read] do
          without_token_permissions { forbids :show }

          permits :show
        end

        with_permissions %w[product.tokens.generate] do
          without_token_permissions { forbids :create }

          permits :create
        end

        with_wildcard_permissions do
          without_token_permissions do
            forbids :show, :create
          end

          permits :show, :create
        end

        with_default_permissions do
          without_token_permissions do
            forbids :show, :create
          end

          permits :show, :create
        end

        without_permissions do
          forbids :show, :create
        end
      end
    end

    with_scenarios %i[as_admin accessing_another_account accessing_a_product accessing_its_tokens] do
      with_token_authentication do
        with_permissions %w[product.tokens.read] do
          forbids :index
        end

        with_wildcard_permissions { forbids :index }
        with_default_permissions  { forbids :index }
        without_permissions       { forbids :index }
      end
    end

    with_scenarios %i[as_admin accessing_another_account accessing_a_product accessing_its_token] do
      with_token_authentication do
        with_permissions %w[product.tokens.read] do
          forbids :show
        end

        with_permissions %w[product.tokens.generate] do
          forbids :create
        end

        with_wildcard_permissions do
          forbids :show, :create
        end

        with_default_permissions do
          forbids :show, :create
        end

        without_permissions do
          forbids :show, :create
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[as_product accessing_itself accessing_its_tokens] do
      with_token_authentication do
        with_permissions %w[product.tokens.read] do
          permits :index
        end

        with_wildcard_permissions { permits :index }
        with_default_permissions  { permits :index }
        without_permissions       { forbids :index }
      end
    end

    with_scenarios %i[as_product accessing_itself accessing_its_token] do
      with_token_authentication do
        with_permissions %w[product.tokens.read] do
          permits :show
        end

        with_wildcard_permissions do
          forbids :create
          permits :show
        end

        with_default_permissions do
          forbids :create
          permits :show
        end

        without_permissions do
          forbids :show, :create
        end
      end
    end

    with_scenarios %i[as_product accessing_a_product accessing_its_tokens] do
      with_token_authentication do
        with_permissions %w[product.tokens.read] do
          forbids :index
        end

        with_wildcard_permissions { forbids :index }
        with_default_permissions  { forbids :index }
        without_permissions       { forbids :index }
      end
    end

    with_scenarios %i[as_product accessing_a_product accessing_its_token] do
      with_token_authentication do
        with_permissions %w[product.tokens.read] do
          forbids :show
        end

        with_wildcard_permissions do
          forbids :show, :create
        end

        with_default_permissions do
          forbids :show, :create
        end

        without_permissions do
          forbids :show, :create
        end
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[as_license accessing_its_product accessing_its_tokens] do
      with_license_authentication do
        with_wildcard_permissions { forbids :index }
        with_default_permissions  { forbids :index }
        without_permissions       { forbids :index }
      end

      with_token_authentication do
        with_wildcard_permissions { forbids :index }
        with_default_permissions  { forbids :index }
        without_permissions       { forbids :index }
      end
    end

    with_scenarios %i[as_license accessing_its_product accessing_its_token] do
      with_license_authentication do
        with_wildcard_permissions { forbids :show, :create }
        with_default_permissions  { forbids :show, :create }
        without_permissions       { forbids :show, :create }
      end

      with_token_authentication do
        with_wildcard_permissions { forbids :show, :create }
        with_default_permissions  { forbids :show, :create }
        without_permissions       { forbids :show, :create }
      end
    end
  end

  with_role_authorization :user do
    with_scenarios %i[as_user with_licenses accessing_its_product accessing_its_tokens] do
      with_token_authentication do
        with_wildcard_permissions { forbids :index }
        with_default_permissions  { forbids :index }
        without_permissions       { forbids :index }
      end
    end

    with_scenarios %i[as_user with_licenses accessing_its_product accessing_its_token] do
      with_token_authentication do
        with_wildcard_permissions { forbids :show, :create }
        with_default_permissions  { forbids :show, :create }
        without_permissions       { forbids :show, :create }
      end
    end
  end

  without_authorization do
    with_scenarios %i[as_anonymous accessing_a_product accessing_its_tokens] do
      without_authentication do
        forbids :index
      end
    end

    with_scenarios %i[as_anonymous accessing_a_product accessing_its_token] do
      without_authentication do
        forbids :show, :create
      end
    end
  end
end
