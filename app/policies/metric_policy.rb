# frozen_string_literal: true

class MetricPolicy < ApplicationPolicy

  def index?
    bearer.role?(:admin, :developer, :sales_agent)
  end

  def show?
    bearer.role?(:admin, :developer, :sales_agent)
  end

  def count?
    bearer.role?(:admin, :developer, :sales_agent)
  end
end
