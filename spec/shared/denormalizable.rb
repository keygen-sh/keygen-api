# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

shared_examples :denormalizable do
  let(:factory) { described_class.name.demodulize.underscore }
  let(:account) { create(:account) }

  # TODO(ezekg) Write shared spec
end
