# frozen_string_literal: true

# NOTE(ezekg) This is used as a sentinel value during tests to determine
#             whether or not a factory's environment should run through
#             the default flow vs an explicit nil value given during
#             factory initialization.
DEFAULT_ENVIRONMENT = Environment.new(id: nil, code: 'FOR_TEST_ONLY').freeze

module EnvironmentHelper
  module ClassMethods
    def within_environment(code, &)
      context "when in the #{code} environment" do
        let(:environment) { create(:environment, code, account:) }

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
