class ApplicationRecord < ActiveRecord::Base
  include GenerateToken

  self.abstract_class = true
end
