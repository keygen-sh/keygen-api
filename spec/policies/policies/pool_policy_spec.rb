# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Policies::PoolPolicy, type: :policy do
  subject { described_class.new(record, account:, bearer:, token:, policy: _policy) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_a_policy] do
      with_token_authentication do
        with_permissions %w[policy.pool.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_policy] do
      with_token_authentication do
        with_permissions %w[policy.pool.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[policy.pool.pop] do
          without_token_permissions { denies :pop }

          allows :pop
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :pop
          end

          allows :show, :pop
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :pop
          end

          allows :show, :pop
        end

        without_permissions do
          denies :show, :pop
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[accessing_its_policy] do
      with_token_authentication do
        with_permissions %w[policy.pool.read] do
          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_its_policy] do
      with_token_authentication do
        with_permissions %w[policy.pool.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[policy.pool.pop] do
          without_token_permissions { denies :pop }

          allows :pop
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :pop
          end

          allows :show, :pop
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :pop
          end

          allows :show, :pop
        end

        without_permissions do
          denies :show, :pop
        end
      end
    end

    with_scenarios %i[accessing_a_policy] do
      with_token_authentication do
        with_permissions %w[policy.pool.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_policy] do
      with_token_authentication do
        with_permissions %w[policy.pool.read] do
          denies :show
        end

        with_permissions %w[policy.pool.pop] do
          denies :pop
        end

        with_wildcard_permissions do
          denies :show, :pop
        end

        with_default_permissions do
          denies :show, :pop
        end

        without_permissions do
          denies :show, :pop
        end
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[accessing_its_policy] do
      with_license_authentication do
        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end

      with_token_authentication do
        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_its_policy] do
      with_license_authentication do
        with_wildcard_permissions { denies :show, :pop }
        with_default_permissions  { denies :show, :pop }
        without_permissions       { denies :show, :pop }
      end

      with_token_authentication do
        with_wildcard_permissions { denies :show, :pop }
        with_default_permissions  { denies :show, :pop }
        without_permissions       { denies :show, :pop }
      end
    end
  end

  with_role_authorization :user do
    with_scenarios %i[is_licensed accessing_its_policy] do
      with_token_authentication do
        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[is_licensed accessing_its_policy] do
      with_token_authentication do
        with_wildcard_permissions { denies :show, :pop }
        with_default_permissions  { denies :show, :pop }
        without_permissions       { denies :show, :pop }
      end
    end
  end

  without_authorization do
    with_scenarios %i[accessing_a_policy] do
      without_authentication do
        denies :index
      end
    end

    with_scenarios %i[accessing_a_policy] do
      without_authentication do
        denies :show, :pop
      end
    end
  end
end
