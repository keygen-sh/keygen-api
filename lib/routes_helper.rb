class ActionDispatch::Routing::Mapper

  # TODO: Figure out a way to accomplish this in a way that is less hacky
  def namespace(*params)
    @@api_version = params.first if params.first.to_s =~ /\Av\d+\Z/
    super *params
  end

  def resource(name, opts = {}, &block)
    resources(name, {
      path: name.to_s.dasherize
    }.merge(opts), &block)
  end

  def relationship(verb, resource, opts = {})
    case verb
    when :resource
      resources(resource.to_s.dasherize, {
        controller: "/api/#{api_version}/#{parent_resource.name}/relationships/#{resource}"
      }.merge(opts))
    else
      send(verb, resource.to_s.dasherize, {
        to: "/api/#{api_version}/#{parent_resource.name}/relationships/#{opts[:to]}"
      })
    end
  end

  def action(verb, action, opts = {})
    case verb
    when :resource
      resources(action.to_s.dasherize, {
        controller: "/api/#{api_version}/#{parent_resource.name}/actions/#{resource}"
      }.merge(opts))
    else
      send(verb, action.to_s.dasherize, {
        to: "/api/#{api_version}/#{parent_resource.name}/actions/#{opts[:to]}"
      })
    end
  end

  private

  def api_version
    @@api_version
  end
end
