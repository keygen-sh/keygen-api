World Rack::Test::Methods

# Matches:
# $resource[0].attribute (where 0 is an index)
# $resource.attribute (random resource)
# $current.attribute (current user)
def parse_placeholders!(str)
  str.dup.scan /((?<!\\)\$(!)?(~)?([-\w]+)(?:\[(\w+)\])?(?:\.([-.\w]+))?)/ do |pattern, *matches|
    escape, encode, resource, index, attribute = matches

    attribute =
      case attribute&.underscore
      when nil
        :id
      else
        attribute.underscore
      end

    value =
      case resource.underscore
      when "account"
        @account.send attribute
      when "current"
        @bearer.send attribute
      when "crypt"
        @crypt.send(*(index.nil? ? [:sample] : [:[], index.to_i]))
              .send attribute
      when "date"
        case attribute
        when "format"
          Time.current.strftime "%Y-%m-%d"
        else
          Date.send(attribute).to_s
        end
      when "time"
        case attribute
        when /(\d+)\.(\w+)\.(\w+).iso/
          $1.to_i.send($2).send($3).iso8601 3
        when /(\d+)\.(\w+)\.(\w+)/
          $1.to_i.send($2).send $3
        when /(\d+)\.(\w+)/
          $1.to_i.send $2
        when /now/, /current/
          Time.current
        end
      when "null_byte"
        "foo-\\u0000-bar"
      else
        if @account
          @account.send(resource.underscore)
            .all
            .send(*(index.nil? ? [:sample] : [:[], index.to_i]))
            .send attribute
        else
          resource.singularize
            .underscore
            .classify
            .constantize
            .all
            .send(*(index.nil? ? [:sample] : [:[], index.to_i]))
            .send attribute
        end
      end

    if escape
      value = value.to_s.to_json
    else
      value = value.to_s
    end

    if encode
      value = Base64.strict_encode64 value
    end

    str.sub! pattern.to_s, value
  end
end

# Matches:
# resource/$current (current user or account)
# resource/$0 (where 0 is a resource ID)
def parse_path_placeholders!(str)
  str.dup.scan(/([-\w]+)\/((?<!\\)\$(\w+))/) do |resource, pattern, index|
    value =
      case index
      when "current"
        case resource
        when "users", "products"
          @bearer.id
        else
          instance_variable_get("@#{resource.singularize}").id
        end
      else
        if @account
          case resource.underscore
          when "request-logs"
            @account.request_logs.send(:[], index.to_i).id
          when "billing"
            @account.billing.id
          when "pool"
            @account.keys
              .all
              .send(*(index.nil? ? [:sample] : [:[], index.to_i]))
              .id
          else
            @account.send(resource.underscore)
              .all
              .send(*(index.nil? ? [:sample] : [:[], index.to_i]))
              .id
          end
        else
          resource.singularize
            .underscore
            .classify
            .constantize
            .all
            .send(:[], index.to_i)
            .id
        end
      end

    str.sub! pattern.to_s, value
  end
  parse_placeholders! str
end
