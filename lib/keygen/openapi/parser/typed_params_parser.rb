# frozen_string_literal: true

require 'parser/current'

module Keygen
  module OpenAPI
    module Parser
      class TypedParamsParser
        # Parse a controller file and extract all typed_params blocks
        def parse_file(file_path)
          source = File.read(file_path)

          # Handle potential syntax errors gracefully
          ast = begin
            ::Parser::CurrentRuby.parse(source)
          rescue ::Parser::SyntaxError => e
            raise "Syntax error in #{file_path}: #{e.message}"
          end

          controller_name = extract_controller_name(file_path)

          {
            name: controller_name,
            file_path: file_path,
            actions: extract_actions(ast)
          }
        end

        private

        def extract_controller_name(file_path)
          # Extract 'Api::V1::LicensesController' from file path
          File.basename(file_path, '.rb').camelize
        end

        def extract_actions(ast)
          actions = {}
          current_typed_params = nil
          nodes = collect_top_level_nodes(ast)

          nodes.each_with_index do |node, index|
            if typed_params_node?(node)
              current_typed_params = parse_typed_params_block(node)
            elsif method_definition?(node) && current_typed_params
              method_name = node.children[0]
              actions[method_name] = current_typed_params
              current_typed_params = nil
            end
          end

          actions
        end

        def collect_top_level_nodes(ast)
          return [] unless ast

          # Find the class definition
          class_node = find_class_node(ast)
          return [] unless class_node

          # Get class body nodes
          class_body = class_node.children[2]
          return [] unless class_body

          if class_body.type == :begin
            class_body.children
          else
            [class_body]
          end
        end

        def find_class_node(node)
          return nil unless node.is_a?(::Parser::AST::Node)
          return node if node.type == :class

          node.children.each do |child|
            result = find_class_node(child)
            return result if result
          end

          nil
        end

        def typed_params_node?(node)
          return false unless node.is_a?(::Parser::AST::Node)

          node.type == :block &&
            node.children[0].is_a?(::Parser::AST::Node) &&
            node.children[0].type == :send &&
            node.children[0].children[1] == :typed_params
        end

        def method_definition?(node)
          return false unless node.is_a?(::Parser::AST::Node)

          node.type == :def || node.type == :defs
        end

        def parse_typed_params_block(node)
          # node structure:
          # (block
          #   (send nil :typed_params)
          #   (args)
          #   (begin ...))

          block_body = node.children[2]

          {
            format: extract_format(block_body),
            params: extract_params(block_body),
            ee_blocks: extract_ee_blocks(block_body),
            with_blocks: extract_with_blocks(block_body)
          }
        end

        def extract_format(block_body)
          # Look for: format :jsonapi
          format_node = find_send_node(block_body, :format)
          return :jsonapi unless format_node

          format_node.children[2]&.children&.first || :jsonapi
        end

        def extract_params(block_body, parent_path = [], context = {})
          params = []
          return params unless block_body

          nodes = block_body.type == :begin ? block_body.children : [block_body]

          nodes.each do |node|
            next unless param_node?(node)

            param_data = parse_param_node(node, parent_path, context)
            params << param_data if param_data
          end

          params
        end

        def param_node?(node)
          return false unless node.is_a?(::Parser::AST::Node)

          if node.type == :send && node.children[1] == :param
            true
          elsif node.type == :block
            # Check if it's a param block
            send_node = node.children[0]
            send_node.is_a?(::Parser::AST::Node) && send_node.type == :send && send_node.children[1] == :param
          else
            false
          end
        end

        def parse_param_node(node, parent_path, context)
          # Handle both simple params and block params
          send_node = node.type == :block ? node.children[0] : node

          param_name_node = send_node.children[2]
          return nil unless param_name_node

          param_name = param_name_node.type == :sym ? param_name_node.children[0] : param_name_node.to_s

          # Extract options from hash argument
          options = extract_param_options(send_node)

          param_data = {
            name: param_name,
            type: options[:type] || :string,
            optional: options[:optional] || false,
            allow_nil: options[:allow_nil] || false,
            allow_blank: options[:allow_blank] || false,
            inclusion: options[:inclusion],
            depth: options[:depth],
            items: options[:items],
            as: options[:as],
            transform: options[:transform],
            if: options[:if],
            unless: options[:unless],
            noop: options[:noop] || false,
            polymorphic: options[:polymorphic] || false,
            coerce: options[:coerce] || false,
            path: parent_path + [param_name],
            ee_only: context[:ee_only] || false
          }

          # Handle nested params for hash types
          if node.type == :block
            nested_body = node.children[2]
            param_data[:nested_params] = extract_params(nested_body, param_data[:path], context)
          end

          param_data
        end

        def extract_param_options(node)
          options = {}

          # Find hash node in param arguments
          node.children[3..-1].each do |arg|
            next unless arg.is_a?(::Parser::AST::Node)
            next unless arg.type == :hash

            arg.children.each do |pair|
              next unless pair.type == :pair

              key = extract_symbol(pair.children[0])
              value = extract_value(pair.children[1])

              options[key] = value if key
            end
          end

          options
        end

        def extract_symbol(node)
          return nil unless node&.type == :sym
          node.children[0]
        end

        def extract_value(node)
          return nil unless node

          case node.type
          when :sym
            node.children[0]
          when :str
            node.children[0]
          when :int
            node.children[0]
          when :true
            true
          when :false
            false
          when :nil
            nil
          when :hash
            extract_hash_value(node)
          when :array
            node.children.map { |child| extract_value(child) }
          when :block, :send
            # Lambda or proc or method call - store source
            { type: :proc, source: node.loc.expression.source }
          else
            { type: node.type, source: node.loc.expression.source }
          end
        end

        def extract_hash_value(node)
          hash = {}

          node.children.each do |pair|
            next unless pair.type == :pair

            key = extract_symbol(pair.children[0]) || extract_value(pair.children[0])
            value = extract_value(pair.children[1])
            hash[key] = value if key
          end

          hash
        end

        def extract_ee_blocks(block_body)
          ee_blocks = []
          return ee_blocks unless block_body

          traverse_ast(block_body) do |node|
            if ee_block_node?(node)
              ee_block = parse_ee_block(node)
              ee_blocks << ee_block if ee_block
            end
          end

          ee_blocks
        end

        def ee_block_node?(node)
          return false unless node.is_a?(::Parser::AST::Node)
          return false unless node.type == :block

          send_node = node.children[0]
          return false unless send_node.is_a?(::Parser::AST::Node)
          return false unless send_node.type == :send

          receiver = send_node.children[0]
          method = send_node.children[1]

          receiver.is_a?(::Parser::AST::Node) &&
            receiver.type == :const &&
            receiver.children[1] == :Keygen &&
            method == :ee
        end

        def parse_ee_block(node)
          block_body = node.children[2]

          {
            entitled_feature: extract_entitled_feature(block_body),
            params: extract_params(block_body, [], { ee_only: true })
          }
        end

        def extract_entitled_feature(block_body)
          # Look for license.entitled?(:feature_name)
          entitled_node = find_deep_in_ast(block_body) do |n|
            n.is_a?(::Parser::AST::Node) &&
              n.type == :send &&
              n.children[1] == :entitled? &&
              n.children[2]&.type == :sym
          end

          return nil unless entitled_node

          entitled_node.children[2].children[0]
        end

        def extract_with_blocks(block_body)
          with_blocks = []
          return with_blocks unless block_body

          traverse_ast(block_body) do |node|
            if with_block_node?(node)
              with_block = parse_with_block(node)
              with_blocks << with_block if with_block
            end
          end

          with_blocks
        end

        def with_block_node?(node)
          return false unless node.is_a?(::Parser::AST::Node)
          return false unless node.type == :block

          send_node = node.children[0]
          send_node.is_a?(::Parser::AST::Node) &&
            send_node.type == :send &&
            send_node.children[1] == :with
        end

        def parse_with_block(node)
          send_node = node.children[0]
          block_body = node.children[2]

          # Extract condition from hash argument
          condition = extract_with_condition(send_node)

          {
            condition: condition,
            params: extract_params(block_body, [], {})
          }
        end

        def extract_with_condition(send_node)
          # Look for hash argument with :if or :unless key
          send_node.children[2..-1].each do |arg|
            next unless arg.is_a?(::Parser::AST::Node)
            next unless arg.type == :hash

            arg.children.each do |pair|
              next unless pair.type == :pair

              key = extract_symbol(pair.children[0])
              next unless [:if, :unless].include?(key)

              return {
                type: key,
                source: pair.children[1].loc.expression.source
              }
            end
          end

          nil
        end

        # Helper methods for AST traversal

        def traverse_ast(node, &block)
          return unless node.is_a?(::Parser::AST::Node)

          block.call(node)

          node.children.each do |child|
            traverse_ast(child, &block)
          end
        end

        def find_send_node(node, method_name)
          found = nil

          traverse_ast(node) do |n|
            if n.type == :send && n.children[1] == method_name
              found = n
              break
            end
          end

          found
        end

        def find_deep_in_ast(node, &block)
          return node if node.is_a?(::Parser::AST::Node) && block.call(node)
          return nil unless node.is_a?(::Parser::AST::Node)

          node.children.each do |child|
            result = find_deep_in_ast(child, &block)
            return result if result
          end

          nil
        end
      end
    end
  end
end
