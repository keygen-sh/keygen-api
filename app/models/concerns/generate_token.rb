module GenerateToken
  extend ActiveSupport::Concern

  def generate_token_for(model, attribute)
    model = model.to_s.classify.constantize
    loop do
      token = SecureRandom.hex
      break token unless model.exists? "#{attribute}": token
    end
  end
end
