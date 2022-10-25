# frozen_string_literal: true

module ConsoleHelper
  module ClassMethods
    def within_console(&)
      context 'when in a Rails console environment' do
        before { stub_const('Rails::Console', Class.new) }

        instance_exec(&)
      end
    end
  end

  def self.included(klass)
    klass.extend ClassMethods
  end
end
