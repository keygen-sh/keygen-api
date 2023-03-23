# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Users::TokenPolicy, type: :policy do
  subject { described_class.new(record, account:, environment:, bearer:, token:, user:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_itself accessing_its_tokens] do
      with_token_authentication do
        with_permissions %w[token.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }

        within_environment :isolated do
          allows :index
        end

        within_environment :shared do
          allows :index
        end

        within_environment nil do
          allows :index
        end
      end
    end

    with_scenarios %i[accessing_itself accessing_its_token] do
      with_token_authentication do
        with_permissions %w[token.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[user.tokens.generate] do
          without_token_permissions { denies :create }

          denies :create
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :create
          end

          denies :create
          allows :show
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :create
          end

          denies :create
          allows :show
        end

        without_permissions do
          denies :show, :create
        end

        within_environment :isolated do
          denies :create
          allows :show
        end

        within_environment :shared do
          denies :create
          allows :show
        end

        within_environment nil do
          denies :create
          allows :show
        end
      end
    end

    with_scenarios %i[accessing_a_user accessing_its_tokens] do
      with_token_authentication do
        with_permissions %w[token.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }

        within_environment :isolated do
          with_bearer_and_token_trait :in_shared_environment do
            denies :index
          end

          with_bearer_and_token_trait :in_nil_environment do
            denies :index
          end

          allows :index
        end

        within_environment :shared do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :index
          end

          with_bearer_and_token_trait :in_nil_environment do
            allows :index
          end

          allows :index
        end

        within_environment nil do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :index
          end

          with_bearer_and_token_trait :in_shared_environment do
            denies :index
          end

          allows :index
        end
      end
    end

    with_scenarios %i[accessing_a_user accessing_its_token] do
      with_token_authentication do
        with_permissions %w[token.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[user.tokens.generate] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :create
          end

          allows :show, :create
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :create
          end

          allows :show, :create
        end

        without_permissions do
          denies :show, :create
        end

        within_environment :isolated do
          with_bearer_and_token_trait :in_shared_environment do
            denies :show, :create
          end

          with_bearer_and_token_trait :in_nil_environment do
            denies :show, :create
          end

          allows :show, :create
        end

        within_environment :shared do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :show, :create
          end

          with_bearer_and_token_trait :in_nil_environment do
            allows :show, :create
          end

          allows :show, :create
        end

        within_environment nil do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :show, :create
          end

          with_bearer_and_token_trait :in_shared_environment do
            denies :show, :create
          end

          allows :show, :create
        end
      end
    end

    with_scenarios %i[accessing_another_account accessing_a_user accessing_its_token] do
      with_token_authentication do
        with_permissions %w[token.read] do
          denies :show
        end

        with_permissions %w[user.tokens.generate] do
          denies :create
        end

        with_wildcard_permissions do
          denies :show, :create
        end

        with_default_permissions do
          denies :show, :create
        end

        without_permissions do
          denies :show, :create
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[accessing_its_user accessing_its_tokens] do
      with_token_authentication do
        with_permissions %w[token.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_its_user accessing_its_token] do
      with_token_authentication do
        with_permissions %w[token.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[user.tokens.generate] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_wildcard_permissions do
          allows :show, :create
        end

        with_default_permissions do
          allows :show, :create
        end

        without_permissions do
          denies :show, :create
        end
      end
    end

    with_scenarios %i[accessing_a_user accessing_its_tokens] do
      with_token_authentication do
        with_permissions %w[token.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_user accessing_its_token] do
      with_token_authentication do
        with_permissions %w[token.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[user.tokens.generate] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_wildcard_permissions do
          allows :show, :create
        end

        with_default_permissions do
          allows :show, :create
        end

        without_permissions do
          denies :show, :create
        end
      end
    end
  end

  with_role_authorization :license do
    with_bearer_trait :with_user do
      with_scenarios %i[accessing_its_user accessing_its_tokens] do
        with_token_authentication do
          with_wildcard_permissions { denies :index }
          with_default_permissions  { denies :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_its_user accessing_its_token] do
        with_license_authentication do
          with_wildcard_permissions do
            denies :show, :create
          end

          with_default_permissions do
            denies :show, :create
          end

          without_permissions do
            denies :show, :create
          end
        end

        with_token_authentication do
          with_wildcard_permissions do
            denies :show, :create
          end

          with_default_permissions do
            denies :show, :create
          end

          without_permissions do
            denies :show, :create
          end
        end
      end
    end

    with_scenarios %i[accessing_a_user accessing_its_tokens] do
      with_token_authentication do
        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_user accessing_its_token] do
      with_license_authentication do
        with_wildcard_permissions do
          denies :show, :create
        end

        with_default_permissions do
          denies :show, :create
        end

        without_permissions do
          denies :show, :create
        end
      end

      with_token_authentication do
        with_wildcard_permissions do
          denies :show, :create
        end

        with_default_permissions do
          denies :show, :create
        end

        without_permissions do
          denies :show, :create
        end
      end
    end
  end

  with_role_authorization :user do
    with_scenarios %i[accessing_itself accessing_its_tokens] do
      with_token_authentication do
        with_permissions %w[token.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_itself accessing_its_token] do
      with_token_authentication do
        with_permissions %w[token.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_wildcard_permissions do
          denies :create
          allows :show
        end

        with_default_permissions do
          denies :create
          allows :show
        end

        without_permissions do
          denies :show, :create
        end
      end
    end

    with_scenarios %i[accessing_a_user accessing_its_tokens] do
      with_token_authentication do
        with_permissions %w[token.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_user accessing_its_token] do
      with_token_authentication do
        with_permissions %w[token.read] do
          denies :show
        end

        with_wildcard_permissions do
          denies :show, :create
        end

        with_default_permissions do
          denies :show, :create
        end

        without_permissions do
          denies :show, :create
        end
      end
    end
  end

  without_authorization do
    with_scenarios %i[accessing_a_user accessing_its_tokens] do
      without_authentication do
        denies :index
      end
    end

    with_scenarios %i[accessing_a_user accessing_its_token] do
      without_authentication do
        denies :show, :create
      end
    end
  end
end
