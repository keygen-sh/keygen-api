# frozen_string_literal: true

module StatementTimeout
  module AbstractAdapterExtension
    def supports_statement_timeout? = false
    def statement_timeout           = raise NotImplementedError
    def statement_timeout=(timeout)
      raise NotImplementedError
    end
  end

  module PostgreSQLAdapterExtension
    def supports_statement_timeout? = true
    def statement_timeout           = @statement_timeout ||= query_value("SHOW statement_timeout")
    def statement_timeout=(timeout)
      @statement_timeout = nil

      internal_exec_query("SET statement_timeout = #{quote(timeout)}")
    end
  end

  module QueryMethodsExtension
    def statement_timeout(timeout)
      timeout = if timeout in ActiveSupport::Duration
                  timeout.in_milliseconds
                else
                  timeout
                end

      connection_pool.with_connection do |connection|
        raise ActiveRecord::AdapterError, "statement_timeout is not supported for the #{connection.class.inspect} adapter" unless
          connection.supports_statement_timeout?

        statement_timeout_was, connection.statement_timeout = connection.statement_timeout, timeout

        yield connection
      ensure
        connection.statement_timeout = statement_timeout_was
      end
    end
  end

  module QueryingExtension
    delegate :statement_timeout, to: :all
  end

  ActiveSupport.on_load :active_record do
    ActiveRecord::ConnectionAdapters::AbstractAdapter.prepend(AbstractAdapterExtension)
    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(PostgreSQLAdapterExtension)
    ActiveRecord::QueryMethods.prepend(QueryMethodsExtension)
    ActiveRecord::Querying.prepend(QueryingExtension)
  end
end
