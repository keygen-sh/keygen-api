# frozen_string_literal: true

require 'rake'

module TaskHelper
  module WorldMethods
    def described_task = self.class.metadata[:description_args].first
    def run_task(name, *args, &)
      task = Rake::Task[name]

      # Ensure task is re-enabled, as Rake tasks are disabled by default
      # after running once within a process.
      task.reenable

      task.invoke(*args)

      if block_given?
        instance_exec(&)
      end
    end
  end

  module ScenarioMethods
    def described_task = metadata[:description_args].first
    def with_task(name, *args, &)
      context "with #{name} Rake task" do
        let(:task) {
          task = Rake::Task[name]

          # Ensure task is re-enabled, as Rake tasks are disabled by default
          # after running once within a process.
          task.reenable

          task
        }

        instance_exec(&)
      end
    end
  end

  def self.included(klass)
    klass.include WorldMethods
    klass.extend ScenarioMethods
  end
end
