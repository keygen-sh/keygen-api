# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Accounts::AnalyticsPolicy, type: :policy do
  subject { described_class.new(account:, bearer:, token:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_analytics] do
      with_token_authentication do
        with_permissions %w[account.analytics.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_wildcard_permissions do
          without_token_permissions { denies :show }

          allows :show
        end

        with_default_permissions do
          without_token_permissions { denies :show }

          allows :show
        end

        without_permissions do
          denies :show
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[accessing_analytics] do
      with_token_authentication do
        with_wildcard_permissions do
          without_token_permissions { denies :show }

          denies :show
        end

        with_default_permissions do
          without_token_permissions { denies :show }

          denies :show
        end

        without_permissions do
          denies :show
        end
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[accessing_analytics] do
      with_license_authentication do
        with_wildcard_permissions do
          denies :show
        end

        with_default_permissions do
          denies :show
        end

        without_permissions do
          denies :show
        end
      end

      with_token_authentication do
        with_wildcard_permissions do
          denies :show
        end

        with_default_permissions do
          denies :show
        end

        without_permissions do
          denies :show
        end
      end
    end
  end

  with_role_authorization :user do
    with_scenarios %i[accessing_analytics] do
      with_token_authentication do
        with_wildcard_permissions do
          denies :show
        end

        with_default_permissions do
          denies :show
        end

        without_permissions do
          denies :show
        end
      end
    end
  end

  without_authorization do
    with_scenarios %i[accessing_analytics] do
      without_authentication do
        denies :show
      end
    end
  end
end
