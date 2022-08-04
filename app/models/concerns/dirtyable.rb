# frozen_string_literal: true

module Dirtyable
  extend ActiveSupport::Concern

  class_methods do
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
    #   user.role_attributes_changed?
    #
    # Which behaves like,
    #
    #   user = User.new
    #   user.role_attributes_changed? # => false
    #   user.assign_attributes(role_attributes: { name: :admin })
    #   user.role_attributes_changed? # => true
    #
    def tracks_dirty_attributes_for(relation)
      raise NotImplementedError, "nested attributes not accepted for #{relation}" unless
        nested_attributes_options.key?(relation)

      module_eval <<~RUBY, __FILE__, __LINE__ + 1
        alias :_#{relation}_attributes= :#{relation}_attributes=


        def #{relation}_attributes_changed? = instance_variable_defined?(:@#{relation}_attributes)
        def #{relation}_attributes          = @#{relation}_attributes
        def #{relation}_attributes=(attributes)
          @#{relation}_attributes = attributes

          self._#{relation}_attributes = attributes
        end
      RUBY
    end
  end
end
