# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe MachinePolicy, type: :policy do
  subject { described_class.new(record, account:, bearer:, token:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_machines] do
      with_token_authentication do
        with_permissions %w[machine.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_machine] do
      with_token_authentication do
        with_permissions %w[machine.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[machine.create] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_permissions %w[machine.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_permissions %w[machine.delete] do
          without_token_permissions { denies :destroy }

          allows :destroy
        end

        with_permissions %w[machine.check-out] do
          without_token_permissions { denies :check_out }

          allows :check_out
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :check_out
          end

          allows :show, :create, :update, :destroy, :check_out
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :check_out
          end

          allows :show, :create, :update, :destroy, :check_out
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end
      end
    end

    with_scenarios %i[accessing_another_account accessing_machines] do
      with_token_authentication do
        with_permissions %w[machine.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_another_account accessing_a_machine] do
      with_token_authentication do
        with_permissions %w[machine.read] do
          denies :show
        end

        with_permissions %w[machine.create] do
          denies :create
        end

        with_permissions %w[machine.update] do
          denies :update
        end

        with_permissions %w[machine.delete] do
          denies :destroy
        end

        with_permissions %w[machine.check-out] do
          denies :check_out
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[accessing_its_machines] do
      with_token_authentication do
        with_permissions %w[machine.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_its_machine] do
      with_token_authentication do
        with_permissions %w[machine.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[machine.create] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_permissions %w[machine.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_permissions %w[machine.delete] do
          without_token_permissions { denies :destroy }

          allows :destroy
        end

        with_permissions %w[machine.check-out] do
          without_token_permissions { denies :check_out }

          allows :check_out
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :check_out
          end

          allows :show, :create, :update, :destroy, :check_out
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :check_out
          end

          allows :show, :create, :update, :destroy, :check_out
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end
      end
    end

    with_scenarios %i[accessing_machines] do
      with_token_authentication do
        with_permissions %w[machine.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_machine] do
      with_token_authentication do
        with_permissions %w[machine.read] do
          denies :show
        end

        with_permissions %w[machine.create] do
          denies :create
        end

        with_permissions %w[machine.update] do
          denies :update
        end

        with_permissions %w[machine.delete] do
          denies :destroy
        end

        with_permissions %w[machine.check-out] do
          denies :check_out
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[accessing_its_machines] do
      with_license_authentication do
        with_permissions %w[machine.read] do
          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end

      with_token_authentication do
        with_permissions %w[machine.read] do
          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_its_machine] do
      with_license_authentication do
        with_permissions %w[machine.read] do
          allows :show
        end

        with_permissions %w[machine.create] do
          allows :create
        end

        with_permissions %w[machine.update] do
          allows :update
        end

        with_permissions %w[machine.delete] do
          allows :destroy
        end

        with_permissions %w[machine.check-out] do
          allows :check_out
        end

        with_wildcard_permissions do
          allows :show, :create, :update, :destroy, :check_out
        end

        with_default_permissions do
          allows :show, :create, :update, :destroy, :check_out
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end
      end

      with_token_authentication do
        with_permissions %w[machine.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[machine.create] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_permissions %w[machine.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_permissions %w[machine.delete] do
          without_token_permissions { denies :destroy }

          allows :destroy
        end

        with_permissions %w[machine.check-out] do
          without_token_permissions { denies :check_out }

          allows :check_out
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :check_out
          end

          allows :show, :create, :update, :destroy, :check_out
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :check_out
          end

          allows :show, :create, :update, :destroy, :check_out
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end
      end
    end

    with_scenarios %i[accessing_machines] do
      with_license_authentication do
        with_permissions %w[machine.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end

      with_token_authentication do
        with_permissions %w[machine.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_machine] do
      with_license_authentication do
        with_permissions %w[machine.read] do
          denies :show
        end

        with_permissions %w[machine.create] do
          denies :create
        end

        with_permissions %w[machine.update] do
          denies :update
        end

        with_permissions %w[machine.delete] do
          denies :destroy
        end

        with_permissions %w[machine.check-out] do
          denies :check_out
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end
      end

      with_token_authentication do
        with_permissions %w[machine.read] do
          denies :show
        end

        with_permissions %w[machine.create] do
          denies :create
        end

        with_permissions %w[machine.update] do
          denies :update
        end

        with_permissions %w[machine.delete] do
          denies :destroy
        end

        with_permissions %w[machine.check-out] do
          denies :check_out
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end
      end
    end
  end

  with_role_authorization :user do
    with_bearer_trait :with_licenses do
      with_scenarios %i[accessing_its_machines] do
        with_token_authentication do
          with_permissions %w[machine.read] do
            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_its_machine] do
        with_token_authentication do
          with_permissions %w[machine.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_permissions %w[machine.create] do
            without_token_permissions { denies :create }

            allows :create
          end

          with_permissions %w[machine.update] do
            without_token_permissions { denies :update }

            allows :update
          end

          with_permissions %w[machine.delete] do
            without_token_permissions { denies :destroy }

            allows :destroy
          end

          with_permissions %w[machine.check-out] do
            without_token_permissions { denies :check_out }

            allows :check_out
          end

          with_wildcard_permissions do
            without_token_permissions do
              denies :show, :create, :update, :destroy, :check_out
            end

            allows :show, :create, :update, :destroy, :check_out
          end

          with_default_permissions do
            without_token_permissions do
              denies :show, :create, :update, :destroy, :check_out
            end

            allows :show, :create, :update, :destroy, :check_out
          end

          without_permissions do
            denies :show, :create, :update, :destroy, :check_out
          end
        end
      end

      with_scenarios %i[accessing_machines] do
        with_token_authentication do
          with_permissions %w[machine.read] do
            denies :index
          end

          with_wildcard_permissions { denies :index }
          with_default_permissions  { denies :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_a_machine] do
        with_token_authentication do
          with_permissions %w[machine.read] do
            denies :show
          end

          with_wildcard_permissions do
            denies :show, :create, :update, :destroy, :check_out
          end

          with_default_permissions do
            denies :show, :create, :update, :destroy, :check_out
          end

          without_permissions do
            denies :show, :create, :update, :destroy, :check_out
          end
        end
      end
    end

    with_scenarios %i[accessing_machines] do
      with_token_authentication do
        with_permissions %w[machine.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_machine] do
      with_token_authentication do
        with_permissions %w[machine.read] do
          denies :show
        end

        with_permissions %w[machine.create] do
          denies :create
        end

        with_permissions %w[machine.update] do
          denies :update
        end

        with_permissions %w[machine.delete] do
          denies :destroy
        end

        with_permissions %w[machine.check-out] do
          denies :check_out
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :check_out
        end
      end
    end
  end

  without_authorization do
    with_scenarios %i[accessing_machines] do
      without_authentication do
        denies :index
      end
    end

    with_scenarios %i[accessing_a_machine] do
      without_authentication do
        denies :show, :create, :update, :destroy, :check_out
      end
    end
  end
end
