class Token < ApplicationRecord
  include Tokenable

  belongs_to :account
  belongs_to :bearer, polymorphic: true

  attr_reader :raw

  def generate!
    @raw, enc = generate_encrypted_token :digest do |token|
      "#{hashid}.#{token}"
    end

    self.digest = enc
    save

    raw
  end
end
