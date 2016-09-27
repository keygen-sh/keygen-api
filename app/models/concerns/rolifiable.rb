module Rolifiable
  extend ActiveSupport::Concern

  included do
    rolify strict: true

    alias_method :allowed?, :has_role?
    alias_method :can?, :has_role?
  end
end
