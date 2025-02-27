# frozen_string_literal: true

# FIXME(ezekg) This is incredibly dirty, hacky and down right bad, but
#              *it works* for quicking writing integration tests.
World Rack::Test::Methods

PLACEHOLDERS = %w[
  account
  billing
  key
  license
  machine
  machine_component
  component
  machine_process
  process
  metric
  plan
  policy
  product
  receipt
  request_log
  role
  token
  user
  webhook_endpoint
  webhook_event
  entitlement
  environment
  policy_entitlement
  license_entitlement
  release
  release_platform
  platform
  release_arch
  arch
  release_filetype
  filetype
  release_channel
  channel
  release_entitlement_constraint
  release_download_link
  release_upgrade_link
  release_upload_link
  release_artifact
  artifact
  release_package
  package
  release_engine
  engine
  constraint
  current
  crypt
  date
  time
  null_byte
  event_type
  event_log
  otp
  group
  group_owner
  owner
  session
]

# Matches:
# $resource[0].attribute (where 0 is an index)
# $resource.attribute (random resource)
# $current.attribute (current user)
def parse_placeholders(str, account:, bearer:, crypt:)
  str.dup.scan /((?<!\\)\$(!)?(~)?([-\w]+)(?:\[([^\]]+)\])?(?:\.([-.\w]+))?)/ do |pattern, *matches|
    escape, encode, resource, index, attribute = matches

    # Return the raw string if this isn't a placeholder (e.g. $foo), as we
    # can assume that this isn't supposed to be a placeholder and is
    # probably just a string containing a $ symbol.
    next unless PLACEHOLDERS.include?(resource.singularize.underscore) ||
                PLACEHOLDERS.include?(resource.pluralize.underscore)

    attribute =
      case attribute&.underscore
      when nil
        'id'
      else
        attribute.underscore
      end

    value =
      case resource.underscore
      when "account"
        case attribute
        when /(\w+)\.(\w+)/
          account.send($1).send $2
        else
          account.send attribute
        end
      when "current"
        bearer.send attribute
      when "token"
        crypt.first
      when "crypt"
        crypt.send(*(index.nil? ? [:sample] : [:[], index.to_i]))
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
        when /(\d+)\.(\w+)\.(\w+).format/
          $1.to_i.send($2).send($3).strftime "%Y-%m-%d"
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
      when "event_types"
        event = index
        event_type = EventType.find_or_create_by! event: event
        event_type.id
      when "otp"
        ROTP::TOTP.new(@second_factor.secret).now
      else
        model =
          if account && resource.singularize != 'account'
            args = case index
                   in UUID_RE => id
                     [:find_by, id:]
                   in nil
                     [:sample]
                   else
                     [:[], index.to_i]
                   end

            case resource.singularize
            when 'constraint'
              account.release_entitlement_constraints.all.send(*args)
            when 'component'
              account.machine_components.all.send(*args)
            when 'process'
              account.machine_processes.all.send(*args)
            when 'artifact'
              account.release_artifacts.all.send(*args)
            when 'package'
              account.release_packages.all.send(*args)
            when 'engine'
              account.release_engines.all.send(*args)
            else
              account.send(resource.underscore).all.send(*args)
            end
          else
            resource.singularize
              .underscore
              .classify
              .constantize
              .all
              .send(*(index.nil? ? [:sample] : [:[], index.to_i]))
          end

        # Handle multiple method calls
        attrs = attribute.to_s.split '.'
        res = model
        attrs.each { |attr|
          res = res.send attr
        }

        # FIXME(ezekg) Format timestamps to ISO 8601
        res = res.iso8601 3 if res.is_a?(ActiveSupport::TimeWithZone)
        res = res.id        if res.is_a?(ActiveRecord::Base)

        res
      end

    if escape
      value = value.to_s.to_json
    else
      value = value.to_s
    end

    if encode
      value = Base64.strict_encode64 value
    end

    str = str.sub(pattern.to_s, value)
  end

  str
end

# Matches:
# resource/$current (current user or account)
# resource/$0 (where 0 is a resource ID)
def parse_path_placeholders(str, account:, bearer:, crypt:)
  str.dup.scan(/([-\w]+)\/((?<!\\)\$(\w+))/) do |resource, pattern, index|
    value =
      case index
      when "current"
        case resource
        when "users", "products"
          bearer.id
        else
          instance_variable_get("@#{resource.singularize}").id
        end
      else
        if account && resource.singularize != 'account'
          case resource.underscore
          when "constraints"
            account.release_entitlement_constraints.send(:[], index.to_i).id
          when "platforms"
            account.release_platforms.send(:[], index.to_i).id
          when "arches"
            account.release_arches.send(:[], index.to_i).id
          when "channels"
            account.release_channels.send(:[], index.to_i).id
          when "filetypes"
            account.release_filetypes.send(:[], index.to_i).id
          when "artifacts"
            account.release_artifacts.send(:[], index.to_i).id
          when "packages"
            account.release_packages.send(:[], index.to_i).id
          when "engines"
            account.release_engines.send(:[], index.to_i).id
          when "request-logs"
            account.request_logs.send(:[], index.to_i).id
          when "components"
            account.machine_components.send(:[], index.to_i).id
          when "processes"
            account.machine_processes.send(:[], index.to_i).id
          when "owners"
            account.group_owners.send(:[], index.to_i).id
          when "billing"
            account.billing.id
          when "pool"
            account.keys
              .all
              .send(*(index.nil? ? [:sample] : [:[], index.to_i]))
              .id
          else
            account.send(resource.underscore)
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

    str = str.sub(pattern.to_s, value)
  end

  str = parse_placeholders(str, account: account, bearer: bearer, crypt: crypt)

  str
end
