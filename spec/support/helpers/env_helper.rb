# frozen_string_literal: true

module EnvHelper
  module InstanceMethods
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

  module ClassMethods
    def with_prestine_env(&)
      prev_env = ENV.to_hash

      context 'with prestine environment' do
        before { ENV.clear }
        after  { ENV.replace(prev_env) }

        instance_exec(&)
      end
    end

    def with_env(**next_env, &)
      prev_env = ENV.to_hash

      context "with environment #{next_env.keys.inspect}" do
        before do
          ENV.update(
            next_env.transform_keys(&:to_s).transform_values(&:to_s),
          )
        end

        after do
          ENV.replace(prev_env)
        end

        instance_exec(&)
      end
    end
  end

  def self.included(klass)
    klass.include InstanceMethods
    klass.extend ClassMethods
  end
end
