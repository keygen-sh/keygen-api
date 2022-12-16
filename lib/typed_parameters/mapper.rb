# frozen_string_literal: true

module TypedParameters
  class Mapper
    def initialize(schema:, controller: nil)
      @controller = controller
      @schema     = schema
    end

    def call(*, &) = raise NotImplementedError

    def self.call(*args, **kwargs, &block)
      new(**kwargs).call(*args, &block)
    end

    private

    attr_reader :controller,
                :schema

    ##
    # depth_first_map performs a postorder DFS-like traversal algorithm
    # over the params. A postorder DFS starts at the leftmost leaf, and
    # works its way through to the rightmost sibling, then it backtracks
    # to the parent node and performs the same all the way up the tree
    # until it reaches the root.
    #
    # The algorithm is used to perform bouncing, coercing, validations
    # and transforms. For example, with transforms, this ensures that
    # the node's children are transformed before the parent.
    #
    # Visualized, the traversal algorithm would look like this:
    #
    #                  ┌───┐
    #                  │ 9 │
    #                  └─┬─┘
    #                    │
    #                  ┌─▼─┐
    #          ┌────┬──┤ 8 ├───────┐
    #          │    │  └─┬─┘       │
    #          │    │    │         │
    #        ┌─▼─┐┌─▼─┐┌─▼─┐     ┌─▼─┐
    #     ┌──┤ 3 ││ 4 ││ 6 │     │ 7 │
    #     │  └─┬─┘└───┘└─┬─┘     └───┘
    #     │    │         │
    #   ┌─▼─┐┌─▼─┐     ┌─▼─┐
    #   │ 1 ││ 2 │     │ 5 │
    #   └───┘└───┘     └───┘
    #
    def depth_first_map(param, &)
      return if param.nil?

      # Postorder DFS, so we'll visit the children first.
      if param.schema.children&.any?
        case param.schema.children
        in Array if param.array?
          if param.schema.indexed?
            param.schema.children.each_with_index { |v, i| self.class.call(param[i], schema: v, controller:, &) }
          else
            param.value.each { |v| self.class.call(v, schema: param.schema.children.first, controller:, &) }
          end
        in Hash if param.hash?
          param.schema.children.each { |k, v| self.class.call(param[k], schema: v, controller:, &) }
        else
        end
      end

      # Then we visit the node.
      yield param

      param
    end
  end
end
