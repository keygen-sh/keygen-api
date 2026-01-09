# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe AsyncMutable, type: :concern do
  temporary_model :person, table_name: nil do
    include AsyncMutable
  end

  it 'should include other async concerns' do
    ancestors = Person.ancestors

    expect(ancestors).to include(
      AsyncCreatable,
      AsyncUpdatable,
      AsyncTouchable,
      AsyncDestroyable,
    )
  end
end
