# frozen_string_literal: true

module AsyncMutable
  extend ActiveSupport::Concern

  include AsyncCreatable, AsyncUpdatable, AsyncTouchable, AsyncDestroyable
end
