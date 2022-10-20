# frozen_string_literal: true

module EnvironmentHelper
  module ClassMethods
    def with_environment(next_env)
      before do
        @prev_env = ENV.to_hash

        ENV.update(
          next_env.transform_keys(&:to_s)
                  .transform_values(&:to_s),
        )
      end

      after do
        ENV.replace(@prev_env)
      end

      yield
    end
    alias :with_env :with_environment
  end

  def self.included(klass)
    klass.extend ClassMethods
  end
end
