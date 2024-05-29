# frozen_string_literal: true

module StatementTimeout
  module QueryMethodsExtension
    def statement_timeout(timeout)
      t = if timeout in ActiveSupport::Duration
            timeout.in_milliseconds
          else
            timeout
          end

      spawn.transaction do
        conn = respond_to?(:lease_connection) ? lease_connection : connection

        conn.execute(
          sanitize_sql(['SET LOCAL statement_timeout = :t', t:]),
        )

        yield conn
      end
    end
  end

  module QueryingExtension
    delegate :statement_timeout, to: :all
  end

  ActiveSupport.on_load :active_record do
    ActiveRecord::QueryMethods.prepend(QueryMethodsExtension)
    ActiveRecord::Querying.prepend(QueryingExtension)
  end
end
