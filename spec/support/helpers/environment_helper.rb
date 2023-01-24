# frozen_string_literal: true

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
