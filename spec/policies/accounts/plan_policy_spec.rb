# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Accounts::PlanPolicy, type: :policy do
  subject { described_class.new(record, account:, environment:, bearer:, token:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_plan] do
      with_token_authentication do
        with_permissions %w[account.plan.read] do
          without_token_permissions do
            denies :show
          end

          allows :show
        end

        with_permissions %w[account.plan.update] do
          without_token_permissions do
            denies :update
          end

          allows :update
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :update
          end

          allows :show, :update
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :update
          end

          allows :show, :update
        end

        without_permissions do
          denies :show, :update
        end
      end
    end
  end

  with_role_authorization :environment do
    within_environment :self do
      with_scenarios %i[accessing_plan] do
        with_token_authentication do
          with_wildcard_permissions do
            without_token_permissions do
              denies :show, :update
            end

            denies :show, :update
          end

          with_default_permissions do
            without_token_permissions do
              denies :show, :update
            end

            denies :show, :update
          end

          without_permissions do
            denies :show, :update
          end
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[accessing_plan] do
      with_token_authentication do
        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :update
          end

          denies :show, :update
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :update
          end

          denies :show, :update
        end

        without_permissions do
          denies :show, :update
        end
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[accessing_plan] do
      with_license_authentication do
        with_wildcard_permissions do
          denies :show, :update
        end

        with_default_permissions do
          denies :show, :update
        end

        without_permissions do
          denies :show, :update
        end
      end

      with_token_authentication do
        with_wildcard_permissions do
          denies :show, :update
        end

        with_default_permissions do
          denies :show, :update
        end

        without_permissions do
          denies :show, :update
        end
      end
    end
  end

  with_role_authorization :user do
    with_scenarios %i[accessing_plan] do
      with_token_authentication do
        with_wildcard_permissions do
          denies :show, :update
        end

        with_default_permissions do
          denies :show, :update
        end

        without_permissions do
          denies :show, :update
        end
      end
    end
  end

  without_authorization do
    with_scenarios %i[accessing_plan] do
      without_authentication do
        denies :show, :update
      end
    end
  end
end
