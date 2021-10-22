class GenerateFlatfileService < BaseService
  class InvalidIncludedResourceError < StandardError; end
  class InvalidResourceError < StandardError; end
  class InvalidTTLError < StandardError; end

  def initialize(account:, resource:, include: nil, ttl: 1.month)
    raise InvalidResourceError.new('invalid resource type') unless
      resource.is_a?(License) ||
      resource.is_a?(Machine)

    raise InvalidTTLError.new('must be greater than or equal to 3600 (1 hour)') if
      ttl.present? && ttl < 1.hour

    @account  = account
    @resource = resource
    @include  = include
    @ttl      = ttl
  end

  def call
    resource_type = resource.class.name.upcase
    generated_at  = Time.current
    expires_at    = generated_at + ttl
    dataset       = generate_dataset()
    sig           = sign_dataset(dataset)

    <<~TXT
      -----BEGIN #{resource_type} FLATFILE-----
      #{generated_at.iso8601(3)}
      #{expires_at.iso8601(3)}
      #{dataset}
      #{sig}
      -----END #{resource_type} FLATFILE-----
    TXT
  end

  private

  def generate_dataset
    # FIXME(ezekg) We're rendering things manually so that we have better control over queries,
    #              so that we can avoid any N+1 queries due to includes.
    renderer          = Keygen::JSONAPI::Renderer.new(context: :flatfile)
    rendered_resource = renderer.render(resource)
    rendered_includes = render_includes(renderer)

    if rendered_includes.present?
      rendered_resource[:include] = rendered_includes
    end

    rendered_resource.to_json
  end

  def sign_dataset(dataset)
  end

  def render_includes(renderer)
    return nil if
      include.nil?

    included_resource_types = include.to_s.split(',').uniq
    return nil if
      included_resource_types.empty?

    included_resources = []

    included_resource_types.each do |resource_type|
      case resource_type
      when 'license.entitlements'
        raise InvalidIncludedResourceError.new('invalid included resource type: license.entitlements') unless
          resource.is_a?(Machine)

        included_resources << renderer.render(resource.license.entitlements.limit(100))
      when 'license'
        raise InvalidIncludedResourceError.new('invalid included resource type: license') unless
          resource.is_a?(Machine)

        included_resources << renderer.render(resource.license)
      when 'entitlements'
        raise InvalidIncludedResourceError.new('invalid included resource type: entitlements') unless
          resource.is_a?(License)

        included_resources << renderer.render(resource.entitlements.limit(100))
      when 'machines'
        raise InvalidIncludedResourceError.new('invalid included resource type: machines') unless
          resource.is_a?(License)

        included_resources << renderer.render(resource.machines.limit(100))
      else
        raise InvalidIncludedResourceError.new("invalid included resource type: #{resource_type}")
      end
    end

    included_resources.uniq.flatten
  end

  attr_reader :account, :resource, :include, :ttl
end
