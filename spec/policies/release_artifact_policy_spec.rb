# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe ReleaseArtifactPolicy, type: :policy do
  subject { described_class.new(record, account:, bearer:, token:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_artifacts] do
      with_token_authentication do
        with_permissions %w[artifact.read release.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_an_artifact] do
      with_token_authentication do
        with_permissions %w[artifact.download artifact.read release.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[artifact.create] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_permissions %w[artifact.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_permissions %w[artifact.delete] do
          without_token_permissions { denies :destroy }

          allows :destroy
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy
          end

          allows :show, :create, :update, :destroy
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy
          end

          allows :show, :create, :update, :destroy
        end

        without_permissions do
          denies :show, :create, :update, :destroy
        end
      end
    end

    with_scenarios %i[accessing_another_account accessing_artifacts] do
      with_token_authentication do
        with_permissions %w[artifact.read release.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_another_account accessing_an_artifact] do
      with_token_authentication do
        with_permissions %w[artifact.download artifact.read release.read] do
          denies :show
        end

        with_permissions %w[artifact.create] do
          denies :create
        end

        with_permissions %w[artifact.update] do
          denies :update
        end

        with_permissions %w[artifact.delete] do
          denies :destroy
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

  with_role_authorization :product do
    with_scenarios %i[accessing_its_artifacts] do
      with_token_authentication do
        with_permissions %w[artifact.read release.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_its_artifact] do
      with_token_authentication do
        with_permissions %w[artifact.download artifact.read release.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[artifact.create] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_permissions %w[artifact.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_permissions %w[artifact.delete] do
          without_token_permissions { denies :destroy }

          allows :destroy
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy
          end

          allows :show, :create, :update, :destroy
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy
          end

          allows :show, :create, :update, :destroy
        end

        without_permissions do
          denies :show, :create, :update, :destroy
        end
      end
    end

    with_scenarios %i[accessing_artifacts] do
      with_token_authentication do
        with_permissions %w[artifact.read release.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_an_artifact] do
      with_token_authentication do
        with_permissions %w[artifact.download artifact.read release.read] do
          denies :show
        end

        with_permissions %w[artifact.create] do
          denies :create
        end

        with_permissions %w[artifact.update] do
          denies :update
        end

        with_permissions %w[artifact.delete] do
          denies :destroy
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

  with_role_authorization :license do
    with_scenarios %i[accessing_its_artifacts] do
      with_license_authentication do
        with_permissions %w[artifact.read release.read] do
          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end

      with_token_authentication do
        with_permissions %w[artifact.read release.read] do
          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_its_artifact] do
      with_license_authentication do
        with_permissions %w[artifact.download artifact.read release.read] do
          allows :show
        end

        with_wildcard_permissions do
          denies :create, :update, :destroy
          allows :show
        end

        with_default_permissions do
          denies :create, :update, :destroy
          allows :show
        end

        without_permissions do
          denies :show, :create, :update, :destroy
        end
      end

      with_token_authentication do
        with_permissions %w[artifact.download artifact.read release.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_wildcard_permissions do
          denies :create, :update, :destroy
          allows :show
        end

        with_default_permissions do
          denies :create, :update, :destroy
          allows :show
        end

        without_permissions do
          denies :show, :create, :update, :destroy
        end
      end
    end

    with_scenarios %i[accessing_artifacts] do
      with_license_authentication do
        with_permissions %w[artifact.read release.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end

      with_token_authentication do
        with_permissions %w[artifact.read release.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_an_artifact] do
      with_license_authentication do
        with_permissions %w[artifact.download artifact.read release.read] do
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
        with_permissions %w[artifact.download artifact.read release.read] do
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
    end
  end

  with_role_authorization :user do
    with_scenarios %i[is_licensed accessing_its_artifacts] do
      with_token_authentication do
        with_permissions %w[artifact.read release.read] do
          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[is_licensed accessing_its_artifact] do
      with_token_authentication do
        with_permissions %w[artifact.download artifact.read release.read] do
          allows :show
        end

        with_wildcard_permissions do
          denies :create, :update, :destroy
          allows :show
        end

        with_default_permissions do
          denies :create, :update, :destroy
          allows :show
        end

        without_permissions do
          denies :show, :create, :update, :destroy
        end
      end
    end

    with_scenarios %i[is_licensed accessing_artifacts] do
      with_token_authentication do
        with_permissions %w[artifact.read release.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[is_licensed accessing_an_artifact] do
      with_token_authentication do
        with_permissions %w[artifact.download artifact.read release.read] do
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
    end

    with_scenarios %i[accessing_artifacts] do
      with_token_authentication do
        with_permissions %w[artifact.read release.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_an_artifact] do
      with_token_authentication do
        with_permissions %w[artifact.download artifact.read release.read] do
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
    end
  end

  without_authorization do
    with_scenarios %i[accessing_artifacts] do
      without_authentication do
        denies :index
      end
    end

    with_scenarios %i[accessing_an_artifact] do
      without_authentication do
        denies :show, :create, :update, :destroy
      end
    end
  end
end
