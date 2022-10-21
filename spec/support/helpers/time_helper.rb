# frozen_string_literal: true

module TimeHelper
  def with_time(t)
    travel_to t do
      yield
    end
  end
end
