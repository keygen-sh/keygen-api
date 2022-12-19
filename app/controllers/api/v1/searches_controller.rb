# frozen_string_literal: true

module Api::V1
  class SearchesController < Api::V1::BaseController
    class UnsupportedSearchTypeError < StandardError; end
    class EmptyQueryError < StandardError; end

    SEARCH_MIN_QUERY_SIZE = 3.freeze
    SEARCH_OPS            = %i[AND OR].freeze
    SEARCH_MODELS         = [
      Entitlement.name,
      RequestLog.name,
      Product.name,
      Policy.name,
      License.name,
      Machine.name,
      User.name,
      Release.name,
    ].freeze

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!

    typed_params {
      format :jsonapi

      param :meta, type: :hash do
        param :type, type: :string
        param :op, type: :string, optional: true
        param :query, type: :hash, allow_non_scalars: true
      end
    }
    def search
      query, type = search_meta.fetch_values(:query, :type)
      op          = search_meta.fetch(:op) { :AND }.to_sym
      model       = type.underscore.classify.safe_constantize

      raise UnsupportedSearchTypeError if
        model.nil?

      raise EmptyQueryError if
        query.empty?

      raise UnsupportedSearchOperationError unless
        SEARCH_OPS.include?(op)

      raise UnsupportedSearchTypeError unless
        SEARCH_MODELS.include?(model.name)

      raise UnsupportedSearchTypeError unless
        current_account.associated_to?(type.underscore.pluralize)

      authorize! model,
        with: SearchPolicy

      res = model.where(account: current_account)

      # Special cases for certain models
      case
      when model == RequestLog
        start_date = 30.days.ago.beginning_of_day
        end_date   = Time.current

        # Limit request log searches to last 30 days to improve perf
        res = res.where('request_logs.created_at >= :start_date AND request_logs.created_at <= :end_date', start_date: start_date, end_date: end_date)
      end

      query.each do |key, value|
        attribute = key.to_s.underscore.parameterize(separator: '_')

        if !res.respond_to?("search_#{attribute}")
          return render_bad_request(
            detail: "search query '#{attribute.camelize(:lower)}' is not supported for resource type '#{type.camelize(:lower)}'",
            source: { pointer: "/meta/query/#{attribute.camelize(:lower)}" }
          )
        end

        case attribute.to_sym
        when :metadata
          if !value.is_a?(Hash)
            return render_bad_request(
              detail: "search query for 'metadata' must be a hash of key-value search terms",
              source: { pointer: "/meta/query/metadata" }
            )
          end

          if value.any? { |k, v| v.is_a?(String) && v.size < SEARCH_MIN_QUERY_SIZE }
            key, _ = value.find { |k, v| v.is_a?(String) && v.size < SEARCH_MIN_QUERY_SIZE }

            return render_bad_request(
              detail: "search query for '#{key.to_s.camelize(:lower)}' is too small (minimum #{SEARCH_MIN_QUERY_SIZE} characters)",
              source: { pointer: "/meta/query/metadata/#{key.to_s.camelize(:lower)}" }
            )
          end

          case op
          when :AND
            res = res.search_metadata(value)
          when :OR
            res = res.or(res.search_metadata(value))
          else
            res = res.none
          end
        else
          if value.is_a?(String) && value.size < SEARCH_MIN_QUERY_SIZE
            return render_bad_request(
              detail: "search query for '#{attribute.camelize(:lower)}' is too small (minimum #{SEARCH_MIN_QUERY_SIZE} characters)",
              source: { pointer: "/meta/query/#{attribute.camelize(:lower)}" }
            )
          end

          case op
          when :AND
            res = res.send("search_#{attribute}", value)
          when :OR
            res = res.or(res.send("search_#{attribute}", value))
          else
            res = res.none
          end
        end
      end

      search_results = apply_pagination(authorized_scope(apply_scopes(res)))
      authorize! search_results,
        to: :index?

      render jsonapi: search_results
    rescue UnsupportedSearchTypeError
      render_bad_request(detail: "search type '#{type.camelize(:lower)}' is not supported", source: { pointer: "/meta/type" })
    rescue EmptyQueryError
      render_bad_request(detail: "search query is required", source: { pointer: "/meta/query" })
    end
  end
end
