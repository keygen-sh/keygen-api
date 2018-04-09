module Api::V1
  class SearchesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!

    # POST /search
    def search
      query, type = search_params[:meta].fetch_values 'query', 'type'
      model = type.classify.constantize rescue nil

      if model.respond_to?(:search) && current_account.respond_to?(type.pluralize)
        authorize model

        res = current_account.send type.pluralize
        query.each do |attribute, text|
          if !res.respond_to?("search_#{attribute}")
            return render_bad_request(
              detail: "unsupported search attribute '#{attribute.camelize(:lower)}' for resource type '#{type.camelize(:lower)}'",
              source: { pointer: "/meta/query/#{attribute.camelize(:lower)}" }
            )
          end

          res = res.send "search_#{attribute}", text
        end

        @search = policy_scope apply_scopes(res).all

        render jsonapi: @search
      else
        render_bad_request(
          detail: "unsupported search type '#{type.camelize(:lower)}'",
          source: { pointer: "/meta/type" }
        )
      end
    end

    private

    typed_parameters do
      options strict: true

      on :search do
        param :meta, type: :hash do
          param :type, type: :string
          param :query, type: :hash
        end
      end
    end
  end
end
