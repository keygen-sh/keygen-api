# frozen_string_literal: true

module Dirtyable
  extend ActiveSupport::Concern

  class_methods do
    ##
    # FIXME(ezekg) Can't find a way to determine whether or not nested attributes
    #              have been provided. This adds a flag we can check.
    #
    # tracks_dirty_attributes_for adds a flag for checking if nested attributes
    # have been provided, vs. checking e.g. role.changed?, which may give false
    # positives since role can be changed outside nested attributes.
    #
    # For example,
    #
    #   accepts_nested_attributes_for :role
    #   tracks_dirty_attributes_for :role
    #
    # Adds the following method,
    #
    #   user.role_attributes_assigned?
    #
    # Which behaves like,
    #
    #   user = User.new
    #   user.role_attributes_assigned? # => false
    #   user.assign_attributes(role_attributes: { name: :admin })
    #   user.role_attributes_assigned? # => true
    #
    def tracks_dirty_attributes_for(relation)
      raise NotImplementedError, 'tracking nested attributes is only supported for active records' unless
        self < ::ActiveRecord::Base

      raise NotImplementedError, "nested attributes not accepted for #{relation}" unless
        nested_attributes_options.key?(relation)

      module_eval <<~RUBY, __FILE__, __LINE__ + 1
        after_save -> { remove_instance_variable(:@#{relation}_attributes) },
          if: :#{relation}_attributes_assigned?

        def #{relation}_attributes_assigned? = instance_variable_defined?(:@#{relation}_attributes)
        def #{relation}_attributes           = @#{relation}_attributes
        def #{relation}_attributes=(attributes)
          @#{relation}_attributes = attributes

          super
        end
      RUBY
    end
  end

  def self.included(klass)
    raise ArgumentError, "cannot be used outside of model (got #{klass.ancestors})" unless
      (klass < ::ActiveModel::Model && klass < ::ActiveModel::Attributes) ||
      klass < ::ActiveRecord::Base

    super(klass)
  end
end
