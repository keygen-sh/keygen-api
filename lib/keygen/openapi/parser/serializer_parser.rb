# frozen_string_literal: true

module Keygen
  module OpenAPI
    module Parser
      class SerializerParser
        # Parse a serializer file and extract structure
        def parse_file(file_path)
          source = File.read(file_path)

          serializer_name = extract_serializer_name(file_path)

          {
            name: serializer_name,
            file_path: file_path,
            type: extract_type(source, serializer_name),
            attributes: extract_attributes(source),
            relationships: extract_relationships(source),
            links: extract_links(source),
            meta: extract_meta(source)
          }
        end

        private

        def extract_serializer_name(file_path)
          File.basename(file_path, '.rb').camelize
        end

        def extract_type(source, serializer_name)
          # Look for: type 'policies'
          if match = source.match(/^\s*type\s+['"]([^'"]+)['"]/)
            match[1]
          else
            # Fallback: derive from serializer name
            serializer_name.gsub('Serializer', '').tableize
          end
        end

        def extract_attributes(source)
          attributes = []

          # Find all attribute definitions
          source.scan(/^\s*attribute\s+:(\w+)(.*)$/) do |attr_name, options|
            attr_data = {
              name: attr_name,
              conditional: extract_conditional(options),
              ee_only: false,
              block: has_block_after?(source, attr_name)
            }

            attributes << attr_data
          end

          # Find EE-only attributes
          extract_ee_blocks(source).each do |ee_block|
            ee_block.scan(/attribute\s+:(\w+)/) do |attr_name|
              # Mark existing attribute as EE or add new one
              existing = attributes.find { |a| a[:name] == attr_name[0] }
              if existing
                existing[:ee_only] = true
              else
                attributes << {
                  name: attr_name[0],
                  ee_only: true,
                  conditional: nil,
                  block: false
                }
              end
            end
          end

          attributes
        end

        def extract_relationships(source)
          relationships = []

          # Find all relationship definitions
          source.scan(/^\s*relationship\s+:(\w+)\s+do/) do |rel_name|
            # Extract the full relationship block
            rel_block = extract_block_content(source, "relationship :#{rel_name}")

            rel_data = {
              name: rel_name[0],
              has_linkage: rel_block.include?('linkage'),
              has_links: rel_block.include?('link'),
              has_meta: rel_block.include?('meta'),
              ee_only: false,
              conditional: extract_conditional(rel_block)
            }

            relationships << rel_data
          end

          # Find EE-only relationships
          extract_ee_blocks(source).each do |ee_block|
            ee_block.scan(/relationship\s+:(\w+)/) do |rel_name|
              existing = relationships.find { |r| r[:name] == rel_name[0] }
              if existing
                existing[:ee_only] = true
              else
                relationships << {
                  name: rel_name[0],
                  has_linkage: true,
                  has_links: true,
                  has_meta: false,
                  ee_only: true,
                  conditional: nil
                }
              end
            end
          end

          relationships
        end

        def extract_links(source)
          links = []

          source.scan(/^\s*link\s+:(\w+)/) do |link_name|
            links << {
              name: link_name[0],
              ee_only: in_ee_block?(source, "link :#{link_name[0]}")
            }
          end

          links
        end

        def extract_meta(source)
          if source.match?(/^\s*meta\s+do/)
            { present: true }
          else
            nil
          end
        end

        def extract_conditional(text)
          # Look for unless: or if: options
          if match = text.match(/(unless|if):\s*->\s*{([^}]+)}/)
            {
              type: match[1].to_sym,
              source: match[2].strip
            }
          else
            nil
          end
        end

        def has_block_after?(source, attr_name)
          # Check if attribute has a block (do...end or {...})
          pattern = /attribute\s+:#{attr_name}.*?\s+do/
          source.match?(pattern)
        end

        def extract_block_content(source, start_pattern)
          lines = source.lines
          start_index = lines.index { |line| line.include?(start_pattern) }
          return '' unless start_index

          # Find matching end
          indent_level = 0
          block_lines = []

          lines[start_index..-1].each do |line|
            block_lines << line
            indent_level += 1 if line.match?(/\s+do\s*$/)
            indent_level -= 1 if line.match?(/^\s*end\s*$/)
            break if indent_level == 0 && block_lines.size > 1
          end

          block_lines.join
        end

        def extract_ee_blocks(source)
          blocks = []

          # Find all ee do...end blocks
          source.scan(/ee\s+do\s*\n(.*?)\n\s*end/m) do |block_content|
            blocks << block_content[0]
          end

          blocks
        end

        def in_ee_block?(source, pattern)
          extract_ee_blocks(source).any? { |block| block.include?(pattern) }
        end
      end
    end
  end
end
