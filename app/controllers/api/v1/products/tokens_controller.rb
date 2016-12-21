module Api::V1::Products
  class TokensController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate_with_token!
    before_action :set_product

    def generate
      authorize @product

      token = TokenGeneratorService.new(
        account: current_account,
        bearer: @product
      ).execute

      render jsonapi: token
    end

    private

    def set_product
      @product = current_account.products.find params[:id]
    end
  end
end
