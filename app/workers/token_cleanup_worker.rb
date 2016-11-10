class TokenCleanupWorker
  include Sidekiq::Worker

  sidekiq_options queue: :cleanup

  def perform(token_id)
    token = Token.find token_id
    return if token.nil?

    if !token.expired?
      raise TokenNotExpiredError
    end

    token.destroy
  end

  class TokenNotExpiredError < StandardError; end
end
