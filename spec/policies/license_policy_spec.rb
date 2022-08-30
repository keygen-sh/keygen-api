# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe LicensePolicy, type: :policy do
  subject { described_class.new(record, account:, bearer:, token:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_licenses] do
      with_token_authentication do
        with_permissions %w[license.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_license] do
      with_token_authentication do
        with_permissions %w[license.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[license.create] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_permissions %w[license.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_permissions %w[license.delete] do
          without_token_permissions { denies :destroy }

          allows :destroy
        end

        with_permissions %w[license.check-out] do
          without_token_permissions { denies :checkout }

          allows :checkout
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :checkout
          end

          allows :show, :create, :update, :destroy, :checkout
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :checkout
          end

          allows :show, :create, :update, :destroy, :checkout
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :checkout
        end
      end
    end

    with_scenarios %i[accessing_another_account accessing_licenses] do
      with_token_authentication do
        with_permissions %w[license.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_another_account accessing_a_license] do
      with_token_authentication do
        with_permissions %w[license.read] do
          denies :show
        end

        with_permissions %w[license.create] do
          denies :create
        end

        with_permissions %w[license.update] do
          denies :update
        end

        with_permissions %w[license.delete] do
          denies :destroy
        end

        with_permissions %w[license.check-out] do
          denies :checkout
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :checkout
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :checkout
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :checkout
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[accessing_its_licenses] do
      with_token_authentication do
        with_permissions %w[license.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_its_license] do
      with_token_authentication do
        with_permissions %w[license.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[license.create] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_permissions %w[license.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_permissions %w[license.delete] do
          without_token_permissions { denies :destroy }

          allows :destroy
        end

        with_permissions %w[license.check-out] do
          without_token_permissions { denies :checkout }

          allows :checkout
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :checkout
          end

          allows :show, :create, :update, :destroy, :checkout
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :checkout
          end

          allows :show, :create, :update, :destroy, :checkout
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :checkout
        end
      end
    end

    with_scenarios %i[accessing_licenses] do
      with_token_authentication do
        with_permissions %w[license.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_license] do
      with_token_authentication do
        with_permissions %w[license.read] do
          denies :show
        end

        with_permissions %w[license.create] do
          denies :create
        end

        with_permissions %w[license.update] do
          denies :update
        end

        with_permissions %w[license.delete] do
          denies :destroy
        end

        with_permissions %w[license.check-out] do
          denies :checkout
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :checkout
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :checkout
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :checkout
        end
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[accessing_itself] do
      with_license_authentication do
        with_permissions %w[license.read] do
          allows :show
        end

        with_permissions %w[license.check-out] do
          allows :checkout
        end

        with_wildcard_permissions do
          denies :create, :update, :destroy
          allows :show, :checkout
        end

        with_default_permissions do
          denies :create, :update, :destroy
          allows :show, :checkout
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :checkout
        end
      end

      with_token_authentication do
        with_permissions %w[license.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[license.check-out] do
          without_token_permissions { denies :checkout }

          allows :checkout
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :checkout
          end

          denies :create, :update, :destroy
          allows :show, :checkout
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :checkout
          end

          denies :create, :update, :destroy
          allows :show, :checkout
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :checkout
        end
      end
    end

    with_scenarios %i[accessing_licenses] do
      with_license_authentication do
        with_permissions %w[license.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end

      with_token_authentication do
        with_permissions %w[license.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_license] do
      with_license_authentication do
        with_permissions %w[license.read] do
          denies :show
        end

        with_permissions %w[license.check-out] do
          denies :checkout
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :checkout
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :checkout
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :checkout
        end
      end

      with_token_authentication do
        with_permissions %w[license.read] do
          denies :show
        end

        with_permissions %w[license.check-out] do
          denies :checkout
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :checkout
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :checkout
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :checkout
        end
      end
    end
  end

  with_role_authorization :user do
    with_scenarios %i[is_licensed accessing_its_licenses] do
      with_token_authentication do
        with_permissions %w[license.read] do
          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[is_licensed accessing_its_license] do
      with_token_authentication do
        with_permissions %w[license.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[license.create] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_permissions %w[license.delete] do
          without_token_permissions { denies :destroy }

          allows :destroy
        end

        with_permissions %w[license.check-out] do
          without_token_permissions { denies :checkout }

          allows :checkout
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :checkout
          end

          allows :show, :create, :destroy, :checkout
          denies :update
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :checkout
          end

          allows :show, :create, :destroy, :checkout
          denies :update
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :checkout
        end
      end
    end

    with_scenarios %i[is_licensed accessing_licenses] do
      with_token_authentication do
        with_permissions %w[license.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[is_licensed accessing_a_license] do
      with_token_authentication do
        with_permissions %w[license.read] do
          denies :show
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :checkout
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :checkout
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :checkout
        end
      end
    end

    with_scenarios %i[accessing_licenses] do
      with_token_authentication do
        with_permissions %w[license.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_license] do
      with_token_authentication do
        with_permissions %w[license.read] do
          denies :show
        end

        with_permissions %w[license.create] do
          denies :create
        end

        with_permissions %w[license.delete] do
          denies :destroy
        end

        with_permissions %w[license.check-out] do
          denies :checkout
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :checkout
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :checkout
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :checkout
        end
      end
    end
  end

  without_authorization do
    with_scenarios %i[accessing_licenses] do
      without_authentication do
        denies :index
      end
    end

    with_scenarios %i[accessing_a_license] do
      without_authentication do
        denies :show, :create, :update, :destroy, :checkout
      end
    end
  end
end
