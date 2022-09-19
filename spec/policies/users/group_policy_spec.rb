# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Users::GroupPolicy, type: :policy do
  subject { described_class.new(record, account:, bearer:, token:, user:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_a_user accessing_its_group] do
      with_token_authentication do
        with_permissions %w[group.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[user.group.update] do
          without_token_permissions { denies :update }

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

    with_scenarios %i[accessing_another_account accessing_a_user accessing_its_group] do
      with_token_authentication do
        with_permissions %w[group.read] do
          denies :show
        end

        with_permissions %w[user.group.update] do
          denies :update
        end

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

  with_role_authorization :product do
    with_scenarios %i[accessing_its_user accessing_its_group] do
      with_token_authentication do
        with_permissions %w[group.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[user.group.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_wildcard_permissions do
          allows :show, :update
        end

        with_default_permissions do
          allows :show, :update
        end

        without_permissions do
          denies :show, :update
        end
      end
    end

    with_scenarios %i[accessing_a_user accessing_its_group] do
      with_token_authentication do
        with_permissions %w[group.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[user.group.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_wildcard_permissions do
          allows :show, :update
        end

        with_default_permissions do
          allows :show, :update
        end

        without_permissions do
          denies :show, :update
        end
      end
    end
  end

  with_role_authorization :license do
    with_bearer_trait :with_user do
      with_scenarios %i[accessing_its_user accessing_its_group] do
        with_license_authentication do
          with_wildcard_permissions do
            denies :update, :show
          end

          with_default_permissions do
            denies :update, :show
          end

          without_permissions do
            denies :update, :show
          end
        end

        with_token_authentication do
          with_wildcard_permissions do
            denies :update, :show
          end

          with_default_permissions do
            denies :update, :show
          end

          without_permissions do
            denies :update, :show
          end
        end
      end
    end

    with_scenarios %i[accessing_a_user accessing_its_group] do
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
    with_scenarios %i[accessing_itself accessing_its_group] do
      with_token_authentication do
        with_permissions %w[group.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_wildcard_permissions do
          denies :update
          allows :show
        end

        with_default_permissions do
          denies :update
          allows :show
        end

        without_permissions do
          denies :show, :update
        end
      end
    end

    with_scenarios %i[accessing_a_user accessing_its_group] do
      with_token_authentication do
        with_permissions %w[group.read] do
          without_token_permissions { denies :show }

          denies :show
        end

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
    with_scenarios %i[accessing_a_user accessing_its_group] do
      without_authentication do
        denies :show, :update
      end
    end
  end
end
