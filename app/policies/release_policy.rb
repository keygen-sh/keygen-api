# frozen_string_literal: true

class ReleasePolicy < ApplicationPolicy

  def index?
    true
  end

  def show?
    true
  end
end
