# frozen_string_literal: true

# NOTE(ezekg) This is used as a sentinel value during tests to determine
#             whether or not a factory's environment should run through
#             the default flow vs an explicit nil value given during
#             factory initialization.
NIL_ENVIRONMENT = Environment.new(id: nil, account: nil, code: 'FOR_TEST_EYES_ONLY').freeze

module EnvironmentHelper
  module ScenarioMethods
    def within_environment(code, &)
      context "when in the #{code.inspect} environment", only: :ee do
        let(:environment) {
          case code
          in :self
            bearer
          in nil
            nil
          else
            create(:environment, code, account:)
          end
        }

        before { Current.environment = environment }
        after  { Current.environment = nil }

        instance_exec(&)
      end
    end
  end

  def self.included(klass)
    klass.extend ScenarioMethods
  end
end
