# frozen_string_literal: true

class TemplateFormatService < BaseService
  TEMPLATE_FORMAT_RE = /{{(\w+)}}/i

  def initialize(template:, **vars)
    @template = template.to_s
    @vars     = vars.with_indifferent_access
  end

  def call
    template.gsub(TEMPLATE_FORMAT_RE) { vars[$1.underscore.parameterize(separator: '_')] }
  end

  private

  attr_reader :template,
              :vars
end
