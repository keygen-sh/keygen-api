# frozen_string_literal: true

require 'pathname'

require_relative '../gems/ping/lib/ping/version'

Gem::Specification.new do |spec|
  # required gem info
  spec.name        = 'ping'
  spec.version     = Ping::VERSION
  spec.description = "An example gem that pings and pongs."

  # supplemental gem info
  spec.summary  = 'Ping pong example.'
  spec.homepage = 'https://keygen.example/gems/ping'
  spec.email    = ['test@keygen.example']
  spec.authors  = ['Keygen']
  spec.license  = 'MIT'

  # files included in the gem
  spec.files = Dir.glob('../gems/ping/**/*')

  # required Ruby version
  spec.required_ruby_version = '>= 3.1'

  # dependencies
  spec.add_runtime_dependency 'rack'

  # dev dependencies
  spec.add_development_dependency 'rspec'
end
