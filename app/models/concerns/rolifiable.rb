module Rolifiable
  extend ActiveSupport::Concern

  included do
    rolify # strict: true
  end
end
