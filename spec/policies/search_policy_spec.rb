# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe SearchPolicy, type: :policy do
  subject { described_class.new(record, account:, environment:, bearer:, token:) }

  with_role_authorization :admin do
    with_scenarios %i[searching] do
      with_token_authentication do
        with_wildcard_permissions { allows :search }
        with_default_permissions  { allows :search }
        without_permissions       { allows :search }
      end
    end
  end

  with_role_authorization :environment do
    within_environment :current do
      with_scenarios %i[searching] do
        with_token_authentication do
          with_wildcard_permissions { denies :search }
          with_default_permissions  { denies :search }
          without_permissions       { denies :search }
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[searching] do
      with_token_authentication do
        with_wildcard_permissions { denies :search }
        with_default_permissions  { denies :search }
        without_permissions       { denies :search }
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[searching] do
      with_license_authentication do
        with_wildcard_permissions { denies :search }
        with_default_permissions  { denies :search }
        without_permissions       { denies :search }
      end

      with_token_authentication do
        with_wildcard_permissions { denies :search }
        with_default_permissions  { denies :search }
        without_permissions       { denies :search }
      end
    end
  end

  with_role_authorization :user do
    with_scenarios %i[searching] do
      with_token_authentication do
        with_wildcard_permissions { denies :search }
        with_default_permissions  { denies :search }
        without_permissions       { denies :search }
      end
    end
  end

  without_authorization do
    with_scenarios %i[searching] do
      without_authentication { denies :search }
    end
  end
end
