World Rack::Test::Methods

# Matches:
# $resource[0].attribute (where 0 is an index)
# $resource.attribute (random resource)
# $current.attribute (current user)
def parse_placeholders!(str)
  str.dup.scan /((?<!\\)\$(!)?([-\w]+)(?:\[(\w+)\])?(?:\.([-.\w]+))?)/ do |pattern, *matches|
    escape, resource, index, attribute = matches

    attribute =
      case attribute&.underscore
      when nil
        :id
      else
        attribute.underscore
      end

    value =
      case resource.underscore
      when "current"
        @bearer.send attribute
      when "crypt"
        @crypt.send(*(index.nil? ? [:sample] : [:[], index.to_i]))
              .send attribute
      when "date"
        Date.send(attribute).to_s
      when "time"
        case attribute
        when /(\d+)\.(\w+)\.(\w+)/
          $1.to_i.send($2).send $3
        when /(\d+)\.(\w+)/
          $1.to_i.send $2
        when /now/, /current/
          Time.current
        end
      else
        if @account and resource.singularize != "account"
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

    str.sub! pattern.to_s, escape ? value.to_s.to_json : value.to_s
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
          when "billing"
            @account.send(resource.underscore).id
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
