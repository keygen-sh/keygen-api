# frozen_string_literal: true

class UpdateNestedKeyCasingToSnakecaseForMetadataMigration < BaseMigration
  description %(updates casing of nested keys in metadata to be snake_case instead of lowerCamelCase)

  migrate if: -> body { body in included: [*] } do |body|
    case body
    in included: [* , { attributes: { metadata: { ** } } }, *] => includes
      includes.each do |record|
        case record
        in attributes: { metadata: { ** } => metadata }
          metadata.each do |key, value|
            case value
            when Hash
              value.deep_transform_keys! { it.to_s.underscore }
            when Array
              value.map do |v|
                next unless
                  v in Hash

                v.deep_transform_keys! { it.to_s.underscore }
              end
            end
          end
        else
        end
      end
    else
    end
  end

  migrate if: -> body { body in data: [*] } do |body|
    case body
    in data: [* , { attributes: { metadata: { ** } } }, *] => records
      records.each do |record|
        case record
        in attributes: { metadata: { ** } => metadata }
          metadata.each do |key, value|
            case value
            when Hash
              value.deep_transform_keys! { it.to_s.underscore }
            when Array
              value.map do |v|
                next unless
                  v in Hash

                v.deep_transform_keys! { it.to_s.underscore }
              end
            end
          end
        else
        end
      end
    else
    end
  end

  migrate if: -> body { body in data: { ** } } do |body|
    case body
    in data: { attributes: { metadata: { ** } => metadata } }
      metadata.each do |key, value|
        case value
        when Hash
          value.deep_transform_keys! { it.to_s.underscore }
        when Array
          value.map do |v|
            next unless
              v in Hash

            v.deep_transform_keys! { it.to_s.underscore }
          end
        end
      end
    else
    end
  end

  response if: -> res { res.status < 400 && res.status != 204 } do |res|
    mime_type, * = Mime::Type.parse(res.content_type.to_s)
    next unless
      mime_type in Mime::Type[:jsonapi | :json]

    next if
      res.body.blank?

    body = JSON.parse(res.body, symbolize_names: true)

    migrate!(body)

    res.body = JSON.generate(body)
  rescue JSON::ParserError => e
    Keygen.logger.exception(e)
  end
end
