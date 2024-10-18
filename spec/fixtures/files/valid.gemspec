# frozen_string_literal: true

Gem::Specification.new do |spec|
  # required gem info
  spec.name        = 'valid'
  spec.version     = '1.0.0'
  spec.description = "A longer description of the gem's functionality."

  # supplemental gem info
  spec.summary  = 'A short description of the gem.'
  spec.homepage = 'https://keygen.example/gems/valid'
  spec.email    = ['test@keygen.example']
  spec.authors  = ['Keygen']
  spec.license  = 'MIT'

  # files included in the gem
  spec.files = [
    'lib/valid.rb',
    'lib/valid/version.rb',
  ]

  # required Ruby version
  spec.required_ruby_version = '>= 3.1'

  # dependencies
  spec.add_runtime_dependency 'some_dependency', '~> 1.0'

  # dev dependencies
  spec.add_development_dependency 'dev_dependency', '~> 1.2'
end
