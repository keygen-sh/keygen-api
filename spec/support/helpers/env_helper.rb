# frozen_string_literal: true

module EnvHelper
  module WorldMethods
    def stub_env(stubbed_key, stubbed_value)
      allow(ENV).to receive(:fetch).and_wrap_original do |method, key, *args, &block|
        key == stubbed_key ? stubbed_value : method.call(key, *args, &block)
      end

      allow(ENV).to receive(:[]).and_wrap_original do |method, key|
        key == stubbed_key ? stubbed_value : method.call(key)
      end

      allow(ENV).to receive(:key?).and_wrap_original do |method, key|
        key == stubbed_key ? true : method.call(key)
      end
    end

    def with_pristine_env(&)
      prev_env = ENV.to_hash

      ENV.clear

      yield
    ensure
      ENV.replace(prev_env)
    end

    def with_env(**next_env, &)
      prev_env = ENV.to_hash

      ENV.update(
        next_env.transform_keys(&:to_s).transform_values(&:to_s),
      )

      yield
    ensure
      ENV.replace(prev_env)
    end
  end

  module ScenarioMethods
    def with_pristine_env(&)
      prev_env = ENV.to_hash

      context 'with pristine environment' do
        before { ENV.clear }
        after  { ENV.replace(prev_env) }

        instance_exec(&)
      end
    end

    def with_env(**next_env, &)
      prev_env = ENV.to_hash

      context "with environment #{next_env.inspect}" do
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
    klass.include WorldMethods
    klass.extend ScenarioMethods
  end
end
