# frozen_string_literal: true

class Hash
  # see: https://hexdocs.pm/elixir/Map.html#split/2
  def split(*keys)
    keys = keys.to_set # for O(1) lookups

    included = {}
    excluded = {}

    each do |k, v|
      if keys.include?(k)
        included[k] = v
      else
        excluded[k] = v
      end
    end

    [included, excluded]
  end
end
