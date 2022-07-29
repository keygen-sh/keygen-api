# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe ProductPolicy, type: :policy do
  subject { described_class.new(context, resource) }

  with_role_authorization :admin do
    with_scenarios %i[as_admin accessing_products] do
      with_token_authentication do
        permits :index, permissions: %w[product.read]
      end
    end

    with_scenarios %i[as_admin accessing_a_product] do
      with_token_authentication do
        permits :show,    permissions: %w[product.read]
        permits :create,  permissions: %w[product.create]
        permits :update,  permissions: %w[product.update]
        permits :destroy, permissions: %w[product.delete]
      end
    end

    with_scenarios %i[as_admin accessing_another_account accessing_products] do
      with_token_authentication do
        forbids :index, permissions: %w[product.read]
      end
    end

    with_scenarios %i[as_admin accessing_another_account accessing_a_product] do
      with_token_authentication do
        forbids :index,   permissions: %w[product.read]
        forbids :show,    permissions: %w[product.read]
        forbids :create,  permissions: %w[product.create]
        forbids :update,  permissions: %w[product.update]
        forbids :destroy, permissions: %w[product.delete]
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[as_product accessing_products] do
      with_token_authentication do
        forbids :index, permissions: %w[product.read]
      end
    end

    with_scenarios %i[as_product accessing_itself] do
      with_token_authentication do
        permits :show,    permissions: %w[product.read]
        forbids :create,  permissions: %w[product.create]
        permits :update,  permissions: %w[product.update]
        forbids :destroy, permissions: %w[product.delete]
      end
    end

    with_scenarios %i[as_product accessing_another_product] do
      with_token_authentication do
        forbids :show,    permissions: %w[product.read]
        forbids :create,  permissions: %w[product.create]
        forbids :update,  permissions: %w[product.update]
        forbids :destroy, permissions: %w[product.delete]
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[as_license accessing_its_products] do
      with_license_authentication do
        permits :index, permissions: %w[product.read]
      end

      with_token_authentication do
        permits :index, permissions: %w[product.read]
      end
    end

    with_scenarios %i[as_license accessing_its_product] do
      with_license_authentication do
        permits :show,    permissions: %w[product.read]
        forbids :create,  permissions: %w[product.create]
        forbids :update,  permissions: %w[product.update]
        forbids :destroy, permissions: %w[product.delete]
      end

      with_token_authentication do
        permits :show,    permissions: %w[product.read]
        forbids :create,  permissions: %w[product.create]
        forbids :update,  permissions: %w[product.update]
        forbids :destroy, permissions: %w[product.delete]
      end
    end

    with_scenarios %i[as_license accessing_other_products] do
      with_license_authentication do
        forbids :index, permissions: %w[product.read]
      end

      with_token_authentication do
        forbids :index, permissions: %w[product.read]
      end
    end

    with_scenarios %i[as_license accessing_another_product] do
      with_license_authentication do
        forbids :show,    permissions: %w[product.read]
        forbids :create,  permissions: %w[product.create]
        forbids :update,  permissions: %w[product.update]
        forbids :destroy, permissions: %w[product.delete]
      end

      with_token_authentication do
        forbids :show,    permissions: %w[product.read]
        forbids :create,  permissions: %w[product.create]
        forbids :update,  permissions: %w[product.update]
        forbids :destroy, permissions: %w[product.delete]
      end
    end
  end

  with_role_authorization :user do
    with_scenarios %i[as_user with_licenses accessing_their_products] do
      with_token_authentication do
        permits :index, permissions: %w[product.read]
      end
    end

    with_scenarios %i[as_user with_licenses accessing_their_product] do
      with_token_authentication do
        permits :show,    permissions: %w[product.read]
        forbids :create,  permissions: %w[product.create]
        forbids :update,  permissions: %w[product.update]
        forbids :destroy, permissions: %w[product.delete]
      end
    end

    with_scenarios %i[as_user with_licenses accessing_other_products] do
      with_token_authentication do
        forbids :index, permissions: %w[product.read]
      end
    end

    with_scenarios %i[as_user with_licenses accessing_another_product] do
      with_token_authentication do
        forbids :show,    permissions: %w[product.read]
        forbids :create,  permissions: %w[product.create]
        forbids :update,  permissions: %w[product.update]
        forbids :destroy, permissions: %w[product.delete]
      end
    end

    with_scenarios %i[as_user accessing_products] do
      with_token_authentication do
        forbids :index, permissions: %w[product.read]
      end
    end

    with_scenarios %i[as_user accessing_a_product] do
      with_token_authentication do
        forbids :show,    permissions: %w[product.read]
        forbids :create,  permissions: %w[product.create]
        forbids :update,  permissions: %w[product.update]
        forbids :destroy, permissions: %w[product.delete]
      end
    end
  end

  without_authorization do
    with_scenarios %i[as_anonymous accessing_products] do
      without_authentication do
        forbids :index, permissions: %w[product.read]
      end
    end

    with_scenarios %i[as_anonymous accessing_a_product] do
      without_authentication do
        forbids :show,    permissions: %w[product.read]
        forbids :create,  permissions: %w[product.create]
        forbids :update,  permissions: %w[product.update]
        forbids :destroy, permissions: %w[product.delete]
      end
    end
  end
end
