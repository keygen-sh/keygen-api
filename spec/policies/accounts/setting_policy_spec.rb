# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Accounts::SettingPolicy, type: :policy do
  subject { described_class.new(record, account:, environment:, bearer:, token:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_its_settings] do
      with_token_authentication do
        with_permissions %w[account.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_wildcard_permissions do
          without_token_permissions { denies :index }

          allows :index
        end

        with_default_permissions  do
          without_token_permissions { denies :index }

          allows :index
        end

        without_permissions { denies :index }
      end
    end

    with_scenarios %i[accessing_its_setting] do
      with_token_authentication do
        with_permissions %w[account.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[account.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_wildcard_permissions do
          without_token_permissions { denies :show, :create, :update, :destroy }

          allows :show, :update, :create, :destroy
        end

        with_default_permissions do
          without_token_permissions { denies :show, :create, :update, :destroy }

          allows :show, :update, :create, :destroy
        end

        without_permissions do
          denies :show, :create, :update, :destroy
        end
      end
    end

    with_scenarios %i[accessing_settings] do
      with_token_authentication do
        with_permissions %w[account.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_setting] do
      with_token_authentication do
        with_permissions %w[account.read] do
          denies :show
        end

        with_permissions %w[account.update] do
          denies :update
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy
        end

        without_permissions do
          denies :show, :create, :update, :destroy
        end
      end
    end
  end

  with_role_authorization :environment do
    within_environment :self do
      with_scenarios %i[accessing_its_settings] do
        with_token_authentication do
          with_permissions %w[account.read] do
            denies :index
          end

          with_wildcard_permissions { denies :index }
          with_default_permissions  { denies :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_its_setting] do
        with_token_authentication do
          with_permissions %w[account.read] do
            without_token_permissions { denies :show }

            denies :show
          end

          with_wildcard_permissions do
            without_token_permissions { denies :show, :create, :update, :destroy }

            denies :show, :create, :update, :destroy
          end

          with_default_permissions do
            without_token_permissions { denies :show, :create, :update, :destroy }

            denies :show, :create, :update, :destroy
          end

          without_permissions do
            denies :show, :create, :update, :destroy
          end
        end
      end
    end

    with_scenarios %i[accessing_settings] do
      with_token_authentication do
        with_permissions %w[account.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_its_setting] do
      with_token_authentication do
        with_permissions %w[account.read] do
          denies :show
        end

        with_wildcard_permissions { denies :show, :create, :update, :destroy }
        with_default_permissions  { denies :show, :create, :update, :destroy }
        without_permissions       { denies :show, :create, :update, :destroy }
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[accessing_its_settings] do
      with_token_authentication do
        with_permissions %w[account.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_its_setting] do
      with_token_authentication do
        with_permissions %w[account.read] do
          without_token_permissions { denies :show }

          denies :show
        end

        with_wildcard_permissions do
          without_token_permissions { denies :show, :create, :update, :destroy }

          denies :show, :create, :update, :destroy
        end

        with_default_permissions do
          without_token_permissions { denies :show, :create, :update, :destroy }

          denies :show, :create, :update, :destroy
        end

        without_permissions do
          denies :show, :create, :update, :destroy
        end
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[accessing_its_settings] do
      with_license_authentication do
        with_permissions %w[account.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end

      with_token_authentication do
        with_permissions %w[account.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_its_setting] do
      with_license_authentication do
        with_permissions %w[account.read] do
          denies :show
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy
        end

        without_permissions do
          denies :show, :create, :update, :destroy
        end
      end

      with_token_authentication do
        with_permissions %w[account.read] do
          without_token_permissions { denies :show }

          denies :show
        end

        with_wildcard_permissions do
          without_token_permissions { denies :show, :create, :update, :destroy }

          denies :show, :create, :update, :destroy
        end

        with_default_permissions do
          without_token_permissions { denies :show, :create, :update, :destroy }

          denies :show, :create, :update, :destroy
        end

        without_permissions do
          denies :show, :create, :update, :destroy
        end
      end
    end
  end

  with_role_authorization :user do
    with_scenarios %i[accessing_its_settings] do
      with_token_authentication do
        with_permissions %w[account.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_its_setting] do
      with_token_authentication do
        with_permissions %w[account.read] do
          without_token_permissions { denies :show }

          denies :show
        end

        with_wildcard_permissions do
          without_token_permissions { denies :show, :create, :update, :destroy }

          denies :show, :create, :update, :destroy
        end

        with_default_permissions do
          without_token_permissions { denies :show, :create, :update, :destroy }

          denies :show, :create, :update, :destroy
        end

        without_permissions do
          denies :show, :create, :update, :destroy
        end
      end
    end
  end

  without_authorization do
    with_scenarios %i[accessing_settings] do
      without_authentication do
        denies :index
      end
    end

    with_scenarios %i[accessing_setting] do
      without_authentication do
        denies :show, :create, :update, :destroy
      end
    end
  end
end
