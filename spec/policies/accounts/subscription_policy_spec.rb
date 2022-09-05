# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Accounts::SubscriptionPolicy, type: :policy do
  subject { described_class.new(account: record, bearer:, token:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_its_account] do
      with_token_authentication do
        with_permissions %w[account.subscription.update] do
          without_token_permissions do
            denies :manage, :pause, :resume, :cancel, :renew
          end

          allows :manage, :pause, :resume, :cancel, :renew
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :manage, :pause, :resume, :cancel, :renew
          end

          allows :manage, :pause, :resume, :cancel, :renew
        end

        with_default_permissions do
          without_token_permissions do
            denies :manage, :pause, :resume, :cancel, :renew
          end

          allows :manage, :pause, :resume, :cancel, :renew
        end

        without_permissions do
          denies :manage, :pause, :resume, :cancel, :renew
        end
      end
    end

    with_scenarios %i[accessing_an_account] do
      with_token_authentication do
        with_permissions %w[account.subscription.update] do
          without_token_permissions do
            denies :manage, :pause, :resume, :cancel, :renew
          end

          denies :manage, :pause, :resume, :cancel, :renew
        end

        with_wildcard_permissions do
          denies :manage, :pause, :resume, :cancel, :renew
        end

        with_default_permissions do
          denies :manage, :pause, :resume, :cancel, :renew
        end

        without_permissions do
          denies :manage, :pause, :resume, :cancel, :renew
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[accessing_its_account] do
      with_token_authentication do
        with_wildcard_permissions do
          without_token_permissions do
            denies :manage, :pause, :resume, :cancel, :renew
          end

          denies :manage, :pause, :resume, :cancel, :renew
        end

        with_default_permissions do
          without_token_permissions do
            denies :manage, :pause, :resume, :cancel, :renew
          end

          denies :manage, :pause, :resume, :cancel, :renew
        end

        without_permissions do
          denies :manage, :pause, :resume, :cancel, :renew
        end
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[accessing_its_account] do
      with_license_authentication do
        with_wildcard_permissions do
          denies :manage, :pause, :resume, :cancel, :renew
        end

        with_default_permissions do
          denies :manage, :pause, :resume, :cancel, :renew
        end

        without_permissions do
          denies :manage, :pause, :resume, :cancel, :renew
        end
      end

      with_token_authentication do
        with_wildcard_permissions do
          denies :manage, :pause, :resume, :cancel, :renew
        end

        with_default_permissions do
          denies :manage, :pause, :resume, :cancel, :renew
        end

        without_permissions do
          denies :manage, :pause, :resume, :cancel, :renew
        end
      end
    end
  end

  with_role_authorization :user do
    with_scenarios %i[accessing_its_account] do
      with_token_authentication do
        with_wildcard_permissions do
          denies :manage, :pause, :resume, :cancel, :renew
        end

        with_default_permissions do
          denies :manage, :pause, :resume, :cancel, :renew
        end

        without_permissions do
          denies :manage, :pause, :resume, :cancel, :renew
        end
      end
    end
  end

  without_authorization do
    with_scenarios %i[accessing_an_account] do
      without_authentication do
        denies :manage, :pause, :resume, :cancel, :renew
      end
    end
  end
end
