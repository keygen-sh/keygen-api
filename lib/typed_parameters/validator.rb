# frozen_string_literal: true

module TypedParameters
  class Validator
    def self.validate(params)
      return if params.nil? || params.validated?

      # Traverse down the param tree until we hit the end of a branch,
      # then start validating up from there, bottom to top. This is
      # kind of like a depth first search.
      if params.schema.children&.any? &&
         ((params.schema.children.is_a?(Hash) && params.value.any? { |k, v| !params[k].validated? }) ||
          (params.schema.children.is_a?(Array) && params.value.any? { !_1.validated? }))
        case params.schema.children
        when Array
          if params.schema.indexed?
            params.schema.children.each_with_index { |v, i| validate(params[i]) }
          else
            params.value.each { |v| validate(v) }
          end
        when Hash
          params.schema.children.each { |k, v| validate(params[k]) }
        end
      else
        params.validated!

        puts(
          validated!: params.safe,
          # parent: params.parent,
        )

        # Delete blanks unless schema allows blanks
        params.delete if
          !params.schema.allow_blank? &&
          params.blank?

        # From the end of the branch, start working our way back up to
        # our root node, validating bottom to top along the way.
        validate(params.parent)
      end

      params.safe
    end
  end
end
