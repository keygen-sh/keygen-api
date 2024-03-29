# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe MetricPolicy, type: :policy do
  subject { described_class.new(record, account:, environment:, bearer:, token:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_metrics] do
      with_token_authentication do
        with_permissions %w[metric.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_metric] do
      with_token_authentication do
        with_permissions %w[metric.read] do
          without_token_permissions { denies :show, :count }

          allows :show, :count
        end

        with_wildcard_permissions do
          without_token_permissions { denies :show, :count }

          allows :show, :count
        end

        with_default_permissions do
          without_token_permissions { denies :show, :count }

          allows :show, :count
        end

        without_permissions do
          denies :show, :count
        end
      end
    end
  end

  with_role_authorization :environment do
    within_environment :self do
      with_scenarios %i[accessing_metrics] do
        with_token_authentication do
          with_wildcard_permissions { denies :index }
          with_default_permissions  { denies :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_a_metric] do
        with_token_authentication do
          with_wildcard_permissions do
            without_token_permissions { denies :show, :count }

            denies :show, :count
          end

          with_default_permissions do
            without_token_permissions { denies :show, :count }

            denies :show, :count
          end

          without_permissions do
            denies :show, :count
          end
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[accessing_metrics] do
      with_token_authentication do
        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_metric] do
      with_token_authentication do
        with_wildcard_permissions do
          without_token_permissions { denies :show, :count }

          denies :show, :count
        end

        with_default_permissions do
          without_token_permissions { denies :show, :count }

          denies :show, :count
        end

        without_permissions do
          denies :show, :count
        end
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[accessing_metrics] do
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

    with_scenarios %i[accessing_a_metric] do
      with_license_authentication do
        with_wildcard_permissions do
          denies :show, :count
        end

        with_default_permissions do
          denies :show, :count
        end

        without_permissions do
          denies :show, :count
        end
      end

      with_token_authentication do
        with_wildcard_permissions do
          denies :show, :count
        end

        with_default_permissions do
          denies :show, :count
        end

        without_permissions do
          denies :show, :count
        end
      end
    end
  end

  with_role_authorization :user do
    with_scenarios %i[accessing_metrics] do
      with_token_authentication do
        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_metric] do
      with_token_authentication do
        with_wildcard_permissions do
          denies :show, :count
        end

        with_default_permissions do
          denies :show, :count
        end

        without_permissions do
          denies :show, :count
        end
      end
    end
  end

  without_authorization do
    with_scenarios %i[accessing_metrics] do
      without_authentication { denies :index }
    end

    with_scenarios %i[accessing_a_metric] do
      without_authentication { denies :show, :count }
    end
  end
end
