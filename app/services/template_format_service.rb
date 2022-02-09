# frozen_string_literal: true

class TemplateFormatService < BaseService
  TEMPLATE_FORMAT_RE = /\{\{(\w+)\}\}/i

  def initialize(template:, **data)
    @template = template.to_s
    @data     = data.with_indifferent_access
  end

  def call
    template.gsub(TEMPLATE_FORMAT_RE) { data[$1.downcase] }
  end

  private

  attr_reader :template,
              :data
end
