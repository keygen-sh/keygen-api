# frozen_string_literal: true

module Analytics
  class Gauge
    class Downloads
      def initialize(account:, environment:, product_id: nil, package_id: nil, release_id: nil)
        @account     = account
        @environment = environment
        @product_id  = product_id
        @package_id  = package_id
        @release_id  = release_id
      end

      def metrics = %w[downloads]
      def count
        event_type_ids = EventType.by_pattern('artifact.downloaded')
                                  .collect(&:id)
        return {} if
          event_type_ids.empty?

        scope = EventLog::Clickhouse.for_account(account)
                                    .for_environment(environment)
                                    .where(
                                      event_type_id: event_type_ids,
                                      created_date: Date.current,
                                    )
                                    .where(
                                      'metadata.product IS NOT NULL',
                                    )

        unless product_id.nil?
          scope = scope.where(
            Arel.sql('metadata.product.:String') => product_id,
          )
        end

        unless package_id.nil?
          scope = scope.where(
            Arel.sql('metadata.package.:String') => package_id,
          )
        end

        unless release_id.nil?
          scope = scope.where(
            Arel.sql('metadata.release.:String') => release_id,
          )
        end

        count = scope.count

        { 'downloads' => count }.reject { _2.zero? }
      end

      private

      attr_reader :account, :environment, :product_id, :package_id, :release_id
    end
  end
end
