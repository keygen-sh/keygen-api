module Resourcifiable
  extend ActiveSupport::Concern

  included do
    resourcify
  end
end
