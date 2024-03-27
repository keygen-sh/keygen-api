# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Group, type: :model do
  it_behaves_like :environmental
  it_behaves_like :accountable
end
