# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Licenses::EntitlementPolicy, type: :policy do
  subject { described_class.new(record, account:, bearer:, token:, license:) }

  with_role_authorization :admin do
    with_license_traits %i[with_entitlements] do
      with_scenarios %i[accessing_a_license accessing_its_entitlements] do
        with_token_authentication do
          with_permissions %w[entitlement.read] do
            without_token_permissions { denies :index }

            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_a_license accessing_its_entitlement] do
        with_token_authentication do
          with_permissions %w[entitlement.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_permissions %w[license.entitlements.attach] do
            allows :attach
          end

          with_permissions %w[license.entitlements.detach] do
            allows :detach
          end

          with_wildcard_permissions do
            without_token_permissions do
              denies :show, :attach, :detach
            end

            allows :show, :attach, :detach
          end

          with_default_permissions do
            without_token_permissions do
              denies :show, :attach, :detach
            end

            allows :show, :attach, :detach
          end

          without_permissions do
            denies :show, :attach, :detach
          end
        end
      end

      with_scenarios %i[accessing_another_account accessing_a_license accessing_its_entitlement] do
        with_token_authentication do
          with_permissions %w[entitlement.read] do
            denies :show
          end

          with_permissions %w[license.entitlements.attach] do
            denies :attach
          end

          with_permissions %w[license.entitlements.detach] do
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
  end

  with_role_authorization :product do
    with_license_traits %i[with_entitlements] do
      with_scenarios %i[accessing_its_license accessing_its_entitlements] do
        with_token_authentication do
          with_permissions %w[entitlement.read] do
            without_token_permissions { denies :index }

            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_its_license accessing_its_entitlement] do
        with_token_authentication do
          with_permissions %w[entitlement.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_permissions %w[license.entitlements.attach] do
            allows :attach
          end

          with_permissions %w[license.entitlements.detach] do
            allows :detach
          end

          with_wildcard_permissions do
            allows :show, :attach, :detach
          end

          with_default_permissions do
            allows :show, :attach, :detach
          end

          without_permissions do
            denies :show, :attach, :detach
          end
        end
      end

      with_scenarios %i[accessing_a_license accessing_its_entitlements] do
        with_token_authentication do
          with_permissions %w[entitlement.read] do
            without_token_permissions { denies :index }

            denies :index
          end

          with_permissions %w[license.entitlements.attach] do
            denies :attach
          end

          with_permissions %w[license.entitlements.detach] do
            denies :detach
          end

          with_wildcard_permissions { denies :index }
          with_default_permissions  { denies :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_a_license accessing_its_entitlement] do
        with_token_authentication do
          with_permissions %w[entitlement.read] do
            without_token_permissions { denies :show }

            denies :show
          end

          with_permissions %w[license.entitlements.attach] do
            without_token_permissions { denies :attach }

            denies :attach
          end

          with_permissions %w[license.entitlements.detach] do
            without_token_permissions { denies :detach }

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
  end

  with_role_authorization :license do
    with_bearer_trait :with_entitlements do
      with_scenarios %i[accessing_itself accessing_its_entitlements] do
        with_token_authentication do
          with_permissions %w[entitlement.read] do
            without_token_permissions { denies :index }

            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_itself accessing_its_entitlement] do
        with_license_authentication do
          with_permissions %w[entitlement.read] do
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

          without_permissions do
            denies :attach, :detach
            denies :show
          end
        end

        with_token_authentication do
          with_permissions %w[entitlement.read] do
            without_token_permissions { denies :show }

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

          without_permissions do
            denies :attach, :detach
            denies :show
          end
        end
      end
    end

    with_scenarios %i[accessing_a_license accessing_its_entitlements] do
      with_token_authentication do
        with_permissions %w[entitlement.read] do
          without_token_permissions { denies :index }

          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_license accessing_its_entitlement] do
      with_license_authentication do
        with_permissions %w[entitlement.read] do
          denies :show
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

      with_token_authentication do
        with_permissions %w[entitlement.read] do
          without_token_permissions { denies :show }

          denies :show
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

  with_role_authorization :user do
    with_bearer_traits %i[with_entitled_licenses] do
      with_scenarios %i[accessing_its_license accessing_its_entitlements] do
        with_token_authentication do
          with_permissions %w[entitlement.read] do
            without_token_permissions { denies :index }

            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_its_license accessing_its_entitlement] do
        with_token_authentication do
          with_permissions %w[entitlement.read] do
            without_token_permissions { denies :show }

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

          without_permissions do
            denies :attach, :detach
            denies :show
          end
        end
      end
    end

    with_license_traits %i[with_entitlements] do
      with_scenarios %i[accessing_a_license accessing_its_entitlements] do
        with_token_authentication do
          with_permissions %w[entitlement.read] do
            without_token_permissions { denies :index }

            denies :index
          end

          with_wildcard_permissions { denies :index }
          with_default_permissions  { denies :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_a_license accessing_its_entitlement] do
        with_token_authentication do
          with_permissions %w[entitlement.read] do
            without_token_permissions { denies :show }

            denies :show
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
  end

  without_authorization do
    with_scenarios %i[accessing_a_license accessing_its_entitlements] do
      without_authentication do
        denies :index
      end
    end

    with_scenarios %i[accessing_a_license accessing_its_entitlement] do
      without_authentication do
        denies :show, :attach, :detach
      end
    end
  end
end
