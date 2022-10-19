# frozen_string_literal: true

module Keygen
  module EE
    class ProtectedRecordError < StandardError; end

    module ProtectedRecord
      module ClassMethods
        [:find_by_sql, :async_find_by_sql, :count_by_sql, :async_find_by_sql, :all, *ActiveRecord::Querying::QUERYING_METHODS].each do |method|
          define_method method do |*args, **kwargs|
            raise ProtectedRecordError, "Querying with #{name}.#{method} is not available in Keygen CE. Please upgrade to Keygen EE." if
              Keygen.console? && Keygen.ce?

            super(*args, **kwargs)
          end
        end
      end

      def self.included(klass)
        klass.extend ClassMethods
      end
    end
  end
end
