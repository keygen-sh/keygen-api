# frozen_string_literal: true

module EnvHelper
  module Methods
    def with_prestine_env(&)
      prev_env = ENV.to_hash
      ENV.clear

      yield

      ENV.replace(prev_env)
    end

    def with_env(**next_env, &)
      prev_env = ENV.to_hash

      before do
        ENV.update(
          next_env.transform_keys(&:to_s).transform_values(&:to_s),
        )
      end

      after do
        ENV.replace(prev_env)
      end

      yield
    end
  end

  def self.included(klass)
    klass.include Methods
    klass.extend Methods
  end
end
