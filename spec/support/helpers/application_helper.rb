# frozen_string_literal: true

module ApplicationHelper
  module ClassMethods
    def within_console(&)
      context 'when in a Rails console environment' do
        before { stub_const('Rails::Console', Class.new) }

        instance_exec(&)
      end
    end

    def within_worker(&)
      context 'when in a Sidekiq worker environment' do
        before { stub_const('Sidekiq::CLI', Class.new) }

        instance_exec(&)
      end
    end

    def within_server(&)
      context 'when in a Rails server environment' do
        before {
          stub_const('Rails::Server', Class.new)
          stub_const('Puma::Server', Class.new)
        }

        instance_exec(&)
      end
    end
  end

  def self.included(klass)
    klass.extend ClassMethods
  end
end
