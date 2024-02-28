# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe UserPolicy, type: :policy do
  subject { described_class.new(record, account:, environment:, bearer:, token:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_admins] do
      with_token_authentication do
        with_permissions %w[admin.read user.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_permissions %w[user.read] do
          denies :index
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

    with_scenarios %i[accessing_an_admin] do
      with_admin_trait :with_no_permissions do
        with_token_authentication do
          with_permissions %w[admin.read user.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_permissions %w[user.read] do
            denies :show
          end

          with_permissions %w[admin.create user.create] do
            without_token_permissions { denies :create }

            allows :create
          end

          with_permissions %w[user.create] do
            denies :create
          end

          with_permissions %w[admin.update user.update] do
            without_token_permissions { denies :update }

            allows :update
          end

          with_permissions %w[user.update] do
            denies :update
          end

          with_permissions %w[admin.delete user.delete] do
            without_token_permissions { denies :destroy }

            allows :destroy
          end

          with_permissions %w[user.delete] do
            denies :destroy
          end

          with_permissions %w[admin.invite user.invite] do
            without_token_permissions { denies :invite }

            allows :invite
          end

          with_permissions %w[user.invite] do
            denies :invite
          end

          with_permissions %w[user.ban] do
            without_token_permissions { denies :ban }

            denies :ban
          end

          with_permissions %w[user.unban] do
            without_token_permissions { denies :unban }

            denies :unban
          end

          with_wildcard_permissions do
            without_token_permissions do
              denies :show, :create, :update, :destroy, :invite, :ban, :unban
            end

            allows :show, :create, :update, :destroy, :invite
            denies :ban, :unban
          end

          with_default_permissions do
            without_token_permissions do
              denies :show, :create, :update, :destroy, :invite, :ban, :unban
            end

            allows :show, :create, :update, :destroy, :invite
            denies :ban, :unban
          end

          without_permissions do
            denies :show, :create, :update, :destroy, :invite, :ban, :unban
          end

          within_environment :isolated do
            with_bearer_and_token_trait :in_shared_environment do
              denies :show, :create, :update, :destroy, :invite, :ban, :unban
            end

            with_bearer_and_token_trait :in_nil_environment do
              denies :show, :create, :update, :destroy, :invite, :ban, :unban
            end

            allows :show, :create, :update, :destroy, :invite
            denies :ban, :unban
          end

          within_environment :shared do
            with_bearer_and_token_trait :in_isolated_environment do
              denies :show, :create, :update, :destroy, :invite, :ban, :unban
            end

            with_bearer_and_token_trait :in_nil_environment do
              allows :show, :create, :update, :destroy, :invite
              denies :ban, :unban
            end

            allows :show, :create, :update, :destroy, :invite
            denies :ban, :unban
          end

          within_environment nil do
            with_bearer_and_token_trait :in_isolated_environment do
              denies :show, :create, :update, :destroy, :invite, :ban, :unban
            end

            with_bearer_and_token_trait :in_shared_environment do
              denies :show, :create, :update, :destroy, :invite, :ban, :unban
            end

            allows :show, :create, :update, :destroy, :invite
            denies :ban, :unban
          end
        end
      end

      with_admin_trait :with_root_permissions do
        with_token_authentication do
          with_permissions %w[admin.create user.create] do
            denies :create
          end

          with_permissions %w[admin.update user.update] do
            denies :update
          end
        end
      end
    end

    with_scenarios %i[accessing_itself] do
      with_token_authentication do
        with_permissions %w[admin.read user.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[user.read] do
          denies :show
        end

        with_permissions %w[admin.update user.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_permissions %w[user.update] do
          denies :update
        end

        with_permissions %w[admin.delete user.delete] do
          without_token_permissions { denies :destroy }

          allows :destroy
        end

        with_permissions %w[user.delete] do
          denies :destroy
        end

        with_permissions %w[user.ban] do
          denies :ban
        end

        with_permissions %w[user.unban] do
          denies :unban
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :invite, :ban, :unban
          end

          allows :show, :create, :update, :destroy, :invite
          denies :ban, :unban
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :invite, :ban, :unban
          end

          allows :show, :create, :update, :destroy, :invite
          denies :ban, :unban
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end
      end
    end

    with_scenarios %i[accessing_users] do
      with_token_authentication do
        with_permissions %w[user.read] do
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

    with_scenarios %i[accessing_a_user] do
      with_token_authentication do
        with_permissions %w[user.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[user.create] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_permissions %w[user.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_permissions %w[user.delete] do
          without_token_permissions { denies :destroy }

          allows :destroy
        end

        with_permissions %w[user.invite] do
          without_token_permissions { denies :invite }

          allows :invite
        end

        with_permissions %w[user.ban] do
          without_token_permissions { denies :ban }

          allows :ban
        end

        with_permissions %w[user.unban] do
          without_token_permissions { denies :unban }

          allows :unban
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :invite, :ban, :unban
          end

          allows :show, :create, :update, :destroy, :invite, :ban, :unban
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :invite, :ban, :unban
          end

          allows :show, :create, :update, :destroy, :invite, :ban, :unban
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end

        within_environment :isolated do
          with_bearer_and_token_trait :in_shared_environment do
            denies :show, :create, :update, :destroy, :invite, :ban, :unban
          end

          with_bearer_and_token_trait :in_nil_environment do
            denies :show, :create, :update, :destroy, :invite, :ban, :unban
          end

          allows :show, :create, :update, :destroy, :invite, :ban, :unban
        end

        within_environment :shared do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :show, :create, :update, :destroy, :invite, :ban, :unban
          end

          with_bearer_and_token_trait :in_nil_environment do
            allows :show, :create, :update, :destroy, :invite, :ban, :unban
          end

          with_user_trait :in_nil_environment do
            denies :create, :update, :destroy, :invite, :ban, :unban
            allows :show
          end

          allows :show, :create, :update, :destroy, :invite, :ban, :unban
        end

        within_environment nil do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :show, :create, :update, :destroy, :invite, :ban, :unban
          end

          with_bearer_and_token_trait :in_shared_environment do
            denies :show, :create, :update, :destroy, :invite, :ban, :unban
          end

          allows :show, :create, :update, :destroy, :invite, :ban, :unban
        end
      end
    end

    with_scenarios %i[accessing_another_account accessing_users] do
      with_token_authentication do
        with_permissions %w[user.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_another_account accessing_a_user] do
      with_token_authentication do
        with_permissions %w[user.read] do
          denies :show
        end

        with_permissions %w[user.create] do
          denies :create
        end

        with_permissions %w[user.update] do
          denies :update
        end

        with_permissions %w[user.delete] do
          denies :destroy
        end

        with_permissions %w[user.invite] do
          denies :invite
        end

        with_permissions %w[user.ban] do
          denies :ban
        end

        with_permissions %w[user.unban] do
          denies :unban
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end
      end
    end
  end

  with_role_authorization :environment do
    within_environment :self do
      with_scenarios %i[accessing_admins] do
        with_token_authentication do
          with_permissions %w[user.read] do
            denies :index
          end

          with_wildcard_permissions { denies :index }
          with_default_permissions  { denies :index }
          without_permissions       { denies :index }

          within_environment :isolated do
            with_bearer_and_token_trait :isolated do
              with_admin_trait :in_shared_environment do
                denies :index
              end

              with_admin_trait :in_nil_environment do
                denies :index
              end

              denies :index
            end

            with_bearer_and_token_trait :shared do
              denies :index
            end
          end

          within_environment :shared do
            with_bearer_and_token_trait :isolated do
              denies :index
            end

            with_bearer_and_token_trait :shared do
              with_admin_trait :in_isolated_environment do
                denies :index
              end

              with_admin_trait :in_nil_environment do
                denies :index
              end

              denies :index
            end
          end

          within_environment nil do
            with_bearer_and_token_trait :isolated do
              denies :index
            end

            with_bearer_and_token_trait :shared do
              denies :index
            end
          end
        end
      end

      with_scenarios %i[accessing_an_admin] do
        with_token_authentication do
          with_permissions %w[user.read] do
            denies :show
          end

          with_permissions %w[user.create] do
            denies :create
          end

          with_permissions %w[user.update] do
            denies :update
          end

          with_permissions %w[user.delete] do
            denies :destroy
          end

          with_permissions %w[user.invite] do
            denies :invite
          end

          with_permissions %w[user.ban] do
            without_token_permissions { denies :ban }

            denies :ban
          end

          with_permissions %w[user.unban] do
            without_token_permissions { denies :unban }

            denies :unban
          end

          with_wildcard_permissions do
            without_token_permissions do
              denies :show, :create, :update, :destroy, :invite, :ban, :unban
            end

            denies :show, :create, :update, :destroy, :invite, :ban, :unban
          end

          with_default_permissions do
            without_token_permissions do
              denies :show, :create, :update, :destroy, :invite, :ban, :unban
            end

            denies :show, :create, :update, :destroy, :invite, :ban, :unban
          end

          without_permissions do
            denies :show, :create, :update, :destroy, :invite, :ban, :unban
          end

          within_environment :isolated do
            with_bearer_and_token_trait :isolated do
              with_user_trait :in_isolated_environment do
                denies :show, :create, :update, :destroy, :invite, :ban, :unban
              end

              with_user_trait :in_nil_environment do
                denies :show, :create, :update, :destroy, :invite, :ban, :unban
              end

              denies :show, :create, :update, :destroy, :invite, :ban, :unban
            end

            with_bearer_and_token_trait :shared do
              denies :show, :create, :update, :destroy, :invite, :ban, :unban
            end
          end

          within_environment :shared do
            with_bearer_and_token_trait :isolated do
              denies :show, :create, :update, :destroy, :invite, :ban, :unban
            end

            with_bearer_and_token_trait :shared do
              with_admin_trait :in_isolated_environment do
                denies :show, :create, :update, :destroy, :invite, :ban, :unban
              end

              with_admin_trait :in_nil_environment do
                denies :show, :create, :update, :destroy, :invite, :ban, :unban
              end

              denies :show, :create, :update, :destroy, :invite, :ban, :unban
            end
          end

          within_environment nil do
            with_bearer_and_token_trait :isolated do
              with_admin_trait :in_isolated_environment do
                denies :show, :create, :update, :destroy, :invite, :ban, :unban
              end

              with_admin_trait :in_shared_environment do
                denies :show, :create, :update, :destroy, :invite, :ban, :unban
              end

              denies :show, :create, :update, :destroy, :invite, :ban, :unban
            end

            with_bearer_and_token_trait :shared do
              with_admin_trait :in_isolated_environment do
                denies :show, :create, :update, :destroy, :invite, :ban, :unban
              end

              with_admin_trait :in_shared_environment do
                denies :show, :create, :update, :destroy, :invite, :ban, :unban
              end

              denies :show, :create, :update, :destroy, :invite, :ban, :unban
            end
          end
        end
      end

      with_scenarios %i[accessing_users] do
        with_token_authentication do
          with_permissions %w[user.read] do
            without_token_permissions { denies :index }

            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }

          within_environment :isolated do
            with_bearer_and_token_trait :isolated do
              with_user_trait :in_shared_environment do
                denies :index
              end

              with_user_trait :in_nil_environment do
                denies :index
              end

              allows :index
            end

            with_bearer_and_token_trait :shared do
              denies :index
            end
          end

          within_environment :shared do
            with_bearer_and_token_trait :isolated do
              denies :index
            end

            with_bearer_and_token_trait :shared do
              with_user_trait :in_isolated_environment do
                denies :index
              end

              with_user_trait :in_nil_environment do
                allows :index
              end

              allows :index
            end
          end

          within_environment nil do
            with_bearer_and_token_trait :isolated do
              denies :index
            end

            with_bearer_and_token_trait :shared do
              denies :index
            end
          end
        end
      end

      with_scenarios %i[accessing_a_user] do
        with_token_authentication do
          with_permissions %w[user.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_permissions %w[user.create] do
            without_token_permissions { denies :create }

            allows :create
          end

          with_permissions %w[user.update] do
            without_token_permissions { denies :update }

            allows :update
          end

          with_permissions %w[user.delete] do
            without_token_permissions { denies :destroy }

            allows :destroy
          end

          with_permissions %w[user.invite] do
            without_token_permissions { denies :invite }

            allows :invite
          end

          with_permissions %w[user.ban] do
            without_token_permissions { denies :ban }

            allows :ban
          end

          with_permissions %w[user.unban] do
            without_token_permissions { denies :unban }

            allows :unban
          end

          with_wildcard_permissions do
            without_token_permissions do
              denies :show, :create, :update, :destroy, :invite, :ban, :unban
            end

            allows :show, :create, :update, :destroy, :invite, :ban, :unban
          end

          with_default_permissions do
            without_token_permissions do
              denies :show, :create, :update, :destroy, :invite, :ban, :unban
            end

            allows :show, :create, :update, :destroy, :invite, :ban, :unban
          end

          without_permissions do
            denies :show, :create, :update, :destroy, :invite, :ban, :unban
          end

          within_environment :isolated do
            with_bearer_and_token_trait :isolated do
              with_user_trait :in_shared_environment do
                denies :show, :create, :update, :destroy, :invite, :ban, :unban
              end

              with_user_trait :in_nil_environment do
                denies :show, :create, :update, :destroy, :invite, :ban, :unban
              end

              allows :show, :create, :update, :destroy, :invite, :ban, :unban
            end

            with_bearer_and_token_trait :shared do
              denies :show, :create, :update, :destroy, :invite, :ban, :unban
            end
          end

          within_environment :shared do
            with_bearer_and_token_trait :isolated do
              denies :show, :create, :update, :destroy, :invite, :ban, :unban
            end

            with_bearer_and_token_trait :shared do
              with_user_trait :in_isolated_environment do
                denies :show, :create, :update, :destroy, :invite, :ban, :unban
              end

              with_user_trait :in_nil_environment do
                denies :create, :update, :destroy, :invite, :ban, :unban
                allows :show
              end

              allows :show, :create, :update, :destroy, :invite, :ban, :unban
            end
          end

          within_environment nil do
            with_bearer_and_token_trait :isolated do
              with_user_trait :in_isolated_environment do
                denies :show, :create, :update, :destroy, :invite, :ban, :unban
              end

              with_user_trait :in_shared_environment do
                denies :show, :create, :update, :destroy, :invite, :ban, :unban
              end

              denies :show, :create, :update, :destroy, :invite, :ban, :unban
            end

            with_bearer_and_token_trait :shared do
              with_user_trait :in_isolated_environment do
                denies :show, :create, :update, :destroy, :invite, :ban, :unban
              end

              with_user_trait :in_shared_environment do
                denies :show, :create, :update, :destroy, :invite, :ban, :unban
              end

              denies :show, :create, :update, :destroy, :invite, :ban, :unban
            end
          end
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[accessing_admins] do
      with_token_authentication do
        with_permissions %w[user.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_an_admin] do
      with_token_authentication do
        with_permissions %w[user.read] do
          denies :show
        end

        with_permissions %w[user.create] do
          denies :create
        end

        with_permissions %w[user.update] do
          denies :update
        end

        with_permissions %w[user.ban] do
          denies :ban
        end

        with_permissions %w[user.unban] do
          denies :unban
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end
      end
    end

    with_scenarios %i[accessing_its_users] do
      with_token_authentication do
        with_permissions %w[user.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_its_user] do
      with_token_authentication do
        with_permissions %w[user.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[user.create] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_permissions %w[user.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_permissions %w[user.ban] do
          without_token_permissions { denies :ban }

          allows :ban
        end

        with_permissions %w[user.unban] do
          without_token_permissions { denies :unban }

          allows :unban
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :invite, :ban, :unban
          end

          allows :show, :create, :update, :ban, :unban
          denies :destroy, :invite
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :invite, :ban, :unban
          end

          allows :show, :create, :update, :ban, :unban
          denies :destroy, :invite
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end
      end
    end

    with_scenarios %i[accessing_users] do
      with_token_authentication do
        with_permissions %w[user.read] do
          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_user] do
      with_token_authentication do
        with_permissions %w[user.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[user.create] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_permissions %w[user.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_permissions %w[user.ban] do
          without_token_permissions { denies :ban }

          allows :ban
        end

        with_permissions %w[user.unban] do
          without_token_permissions { denies :unban }

          allows :unban
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :invite, :ban, :unban
          end

          allows :show, :create, :update, :ban, :unban
          denies :destroy, :invite
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :invite, :ban, :unban
          end

          allows :show, :create, :update, :ban, :unban
          denies :destroy, :invite
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end
      end
    end
  end

  with_role_authorization :license do
    with_bearer_trait :with_owner do
      with_scenarios %i[accessing_its_owner] do
        with_license_authentication do
          with_permissions %w[user.read] do
            allows :show
          end

          with_wildcard_permissions do
            denies :create, :update, :destroy, :invite, :ban, :unban
            allows :show
          end

          with_default_permissions do
            denies :show, :create, :update, :destroy, :invite, :ban, :unban
          end

          without_permissions do
            denies :show, :create, :update, :destroy, :invite, :ban, :unban
          end
        end

        with_token_authentication do
          with_permissions %w[user.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_wildcard_permissions do
            without_token_permissions do
              denies :show, :create, :update, :destroy, :invite, :ban, :unban
            end

            denies :create, :update, :destroy, :invite, :ban, :unban
            allows :show
          end

          with_default_permissions do
            without_token_permissions do
              denies :show, :create, :update, :destroy, :invite, :ban, :unban
            end

            denies :show, :create, :update, :destroy, :invite, :ban, :unban
          end

          without_permissions do
            denies :show, :create, :update, :destroy, :invite, :ban, :unban
          end
        end
      end
    end

    with_scenarios %i[accessing_admins] do
      with_license_authentication do
        with_permissions %w[user.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end

      with_token_authentication do
        with_permissions %w[user.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_an_admin] do
      with_license_authentication do
        with_permissions %w[user.read] do
          denies :show
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end
      end

      with_token_authentication do
        with_permissions %w[user.read] do
          denies :show
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end
      end
    end

    with_scenarios %i[accessing_users] do
      with_license_authentication do
        with_permissions %w[user.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end

      with_token_authentication do
        with_permissions %w[user.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_user] do
      with_license_authentication do
        with_permissions %w[user.read] do
          denies :show
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end
      end

      with_token_authentication do
        with_permissions %w[user.read] do
          denies :show
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end
      end
    end
  end

  with_role_authorization :user do
    with_scenarios %i[accessing_itself] do
      with_token_authentication do
        with_permissions %w[user.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[user.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :invite, :ban, :unban
          end

          denies :create, :destroy, :invite, :ban, :unban
          allows :show, :update
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :invite, :ban, :unban
          end

          denies :create, :destroy, :invite, :ban, :unban
          allows :show, :update
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end
      end
    end

    with_scenarios %i[accessing_admins] do
      with_token_authentication do
        with_permissions %w[user.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_an_admin] do
      with_token_authentication do
        with_permissions %w[user.read] do
          denies :show
        end

        with_permissions %w[user.update] do
          denies :update
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end
      end
    end

    with_scenarios %i[accessing_users] do
      with_token_authentication do
        with_permissions %w[user.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_user] do
      with_token_authentication do
        with_permissions %w[user.read] do
          denies :show
        end

        with_permissions %w[user.update] do
          denies :update
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end
      end
    end
  end

  without_authorization do
    with_scenarios %i[accessing_users] do
      without_authentication do
        denies :index
      end
    end

    with_scenarios %i[accessing_a_user] do
      without_authentication do
        without_account_protection do
          denies :show, :update, :destroy, :invite, :ban, :unban
          allows :create
        end

        with_account_protection do
          denies :show, :create, :update, :destroy, :invite, :ban, :unban
        end
      end
    end
  end
end
