# frozen_string_literal: true

# NOTE(ezekg) This is used as a sentinel value during tests to determine
#             whether or not a factory's environment should run through
#             the default flow vs an explicit nil value given during
#             factory initialization.
NIL_ENVIRONMENT = Environment.new(id: nil, code: 'FOR_TEST_EYES_ONLY').freeze

module EnvironmentHelper
  AUTHZ_ENVIRONMENT = Class.new { def inspect = '<bearer>' }
                           .new.freeze

  module ClassMethods
    def within_environment(code = AUTHZ_ENVIRONMENT, &)
      context "when in the #{code.inspect} environment" do
        unless code == AUTHZ_ENVIRONMENT
          let(:environment) { code.nil? ? nil : create(:environment, code, account:) }
        else
          let(:environment) { bearer }
        end

        before { Current.environment = environment }
        after  { Current.environment = nil }

        instance_exec(&)
      end
    end
  end

  def self.included(klass)
    klass.extend ClassMethods
  end
end
