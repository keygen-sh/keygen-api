class ApplicationRecord < ActiveRecord::Base
  # acts_as_hashids secret: "qLW2ZgYbW4ndzmGfHmfqffC7d2cTVJ", length: 8
  self.abstract_class = true
end
