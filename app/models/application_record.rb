class ApplicationRecord < ActiveRecord::Base
  include Tokenable

  self.abstract_class = true
end
