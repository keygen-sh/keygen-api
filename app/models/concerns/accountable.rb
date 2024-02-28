# frozen_string_literal: true

module Accountable
  extend ActiveSupport::Concern

  included do
    include Dirtyable
  end

  class_methods do
    ##
    # has_account configures the model to be scoped to an account.
    #
    # Use :default to automatically configure a default account for the model.
    # Accepts a proc that resolves into an Account or account ID.
    def has_account(default: nil, **kwargs)
      belongs_to :account, **kwargs

      tracks_attributes :account_id,
                        :account

      # Hook into both initialization and validation to ensure the current account
      # is applied to new records (given no :account was provided).
      after_initialize -> { self.account_id ||= Current.account&.id },
        unless: -> { account_id_attribute_assigned? || account_attribute_assigned? },
        if: -> { new_record? && account_id.nil? }

      before_validation -> { self.account_id ||= Current.account&.id },
        unless: -> { account_id_attribute_assigned? || account_attribute_assigned? },
        if: -> { new_record? && account_id.nil? },
        on: %i[create]

      validates :account,
        presence: { message: 'must exist' }

      # TODO(ezekg) Extract this into a concern or an attr_immutable lib?
      validate on: %i[update] do
        next unless
          account_changed? && account_id != account_id_was

        errors.add(:account, :not_allowed, message: 'is immutable')
      end

      unless default.nil?
        # NOTE(ezekg) These default hooks are in addition to the default hooks above.
        fn = -> {
          value = case default.arity
                  when 1
                    instance_exec(self, &default)
                  when 0
                    instance_exec(&default)
                  else
                    raise ArgumentError, 'expected proc with 0..1 arguments'
                  end

          self.account_id ||= case value
                              in Account => account
                                account.id
                              in String => id
                                id
                              in nil
                                nil
                              end
        }

        # Again, we want to make absolutely sure our default is applied.
        after_initialize unless: -> { account_id_attribute_assigned? || account_attribute_assigned? },
          if: -> { new_record? && !account_id? },
          &fn

        before_validation unless: -> { account_id_attribute_assigned? || account_attribute_assigned? },
          if: -> { new_record? && !account_id? },
          on: %i[create],
          &fn
      end

      # We also want to assert that the model's current account matches
      # all of its :belongs_to associations that are accountable.
      unless (reflections = reflect_on_all_associations(:belongs_to)).empty?
        reflections.reject { _1.name == :account }
                   .each do |reflection|
          # Assert that we're either dealing with a polymorphic association (and in that case
          # we'll perform the account assert later during validation), or we want to
          # assert the :belongs_to has an :account association to assert against.
          next unless
            (reflection.options in polymorphic: true) || reflection.klass < Accountable

          # Perform asserts on create and update.
          validate on: %i[create update] do
            next unless
              account_id_changed? || public_send("#{reflection.foreign_key}_changed?")

            association = public_send(reflection.name)
            next if
              association.nil?

            # Again, assert that the association has an :account association to assert
            # against (this is mainly here for polymorphic associations).
            next unless
              association.class < Accountable

            # Add a validation error if the current model's account does not match
            # its association's account.
            errors.add :account, :not_allowed, message: "must match #{reflection.name} account" unless
              association.account_id == account_id
          end
        end
      end
    end
  end
end
