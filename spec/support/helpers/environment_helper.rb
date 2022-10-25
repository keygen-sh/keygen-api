# frozen_string_literal: true

module EnvironmentHelper
  module Methods
    def with_prestine_env(&)
      prev_env = ENV.to_hash
      ENV.clear

      yield

      ENV.replace(prev_env)
    end

    def with_env(prestine: true, **next_env, &)
      before do
        @prev_env = ENV.to_hash
        next_env  = next_env.transform_keys(&:to_s)
                            .transform_values(&:to_s)

        if prestine
          ENV.replace(next_env)
        else
          ENV.update(next_env)
        end
      end

      after do
        ENV.replace(@prev_env)
      end

      yield
    end
  end

  def self.included(klass)
    klass.include Methods
    klass.extend Methods
  end
end
