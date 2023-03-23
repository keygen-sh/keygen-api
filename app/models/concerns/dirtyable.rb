# frozen_string_literal: true

module Dirtyable
  extend ActiveSupport::Concern

  class_methods do
    ##
    # Override for AR's default assign_attributes method, used when we need
    # to check is an attribute was provided during class instantiation.
    # This is especially when we want to check if a given attribute
    # was explicitly assigned nil.
    #
    # For example,
    #
    #   Current.environment = #<Environment id=1>
    #
    #   license = License.new
    #   license.environment # => #<Environment id=1>
    #   license.environment_assigned? # => false
    #
    #   license = License.new environment: nil
    #   license.environment # => nil
    #   license.environment_assigned? # => true
    #
    #   license = License.new environment: #<Environment id=2>
    #   license.environment # => #<Environment id=2>
    #   license.environment_assigned? # => true
    #
    # As you can see, our environment is nil for the second license. Without
    # this override, we wouldn't be able to determine whether or not :environment
    # was initialized as nil vs nil being explicitly provided. This allows us
    # to conditionally apply a default via the current environment based on
    # whether or not an environment was explicitly passed.
    #
    def tracks_dirty_attributes(*attribute_names)
      raise NotImplementedError, "attributes not accepted for #{self}: #{attribute_names.inspect}" unless
        attribute_names.empty? || attribute_names.all? {
          _1.to_s.in?(self.attribute_names) || (
            self < ::ActiveRecord::Base && (
              _1.to_s.in?(self.column_names) || _1.to_s.in?(reflections.keys)
            )
          )
        }

      module_exec do
        if self <= ActiveRecord::Base
          after_save -> { remove_instance_variable(:@assigned_attributes) },
            if: :assigned_attributes?
        end

        alias :__assign_attributes :assign_attributes

        def assigned_attributes? = instance_variable_defined?(:@assigned_attributes)
        def assign_attributes(attributes)
          @assigned_attributes = (@assigned_attributes || {}).merge(attributes.stringify_keys)

          __assign_attributes(attributes)
        end

        if attribute_names.empty?
          def respond_to_missing?(method_name, ...)
            case /(?<key>.*?)_attribute_assigned\?/.match(method_name)
            in key:
              self.class.attribute_names.include?(key) || (
                self.class < ::ActiveRecord::Base && self.class.reflections.key?(key)
              )
            else
              super
            end
          end

          def method_missing(method_name, ...)
            case /(?<key>.*?)_attribute_assigned\?/.match(method_name)
            in { key: } if self.class.attribute_names.include?(key) || (
                            self.class < ::ActiveRecord::Base && self.class.reflections.key?(key)
                          )
              @assigned_attributes&.key?(key)
            else
              super
            end
          end
        else
          attribute_names.each do |attribute_name|
            define_method :"#{attribute_name}_attribute_assigned?" do
              @assigned_attributes&.key?(attribute_name.to_s)
            end
          end
        end
      end
    end

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
      raise NotImplementedError, 'tracking nested attributes is only supported for active records' unless
        self < ::ActiveRecord::Base

      raise NotImplementedError, "nested attributes not accepted for #{relation}" unless
        nested_attributes_options.key?(relation)

      module_eval <<~RUBY, __FILE__, __LINE__ + 1
        after_save -> { remove_instance_variable(:@#{relation}_attributes) },
          if: :#{relation}_attributes_changed?

        alias :__#{relation}_attributes= :#{relation}_attributes=

        def #{relation}_attributes_changed? = instance_variable_defined?(:@#{relation}_attributes)
        def #{relation}_attributes          = @#{relation}_attributes
        def #{relation}_attributes=(attributes)
          @#{relation}_attributes = attributes

          self.__#{relation}_attributes = attributes
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
