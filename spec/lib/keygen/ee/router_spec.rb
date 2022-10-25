# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root.join('lib', 'keygen')

describe Keygen::EE::Router, type: :ee do
  subject { Keygen::EE::Router::Constraint }

  let(:req) { Rack::Request.new(Rack::MockRequest.env_for('/v1/licenses')) }

  within_ce do
    it 'should return false in a CE env' do
      constraint = subject.new

      expect(constraint.matches?(req)).to be false
    end
  end

  within_ee do
    it 'should return true in an EE env' do
      constraint = subject.new

      expect(constraint.matches?(req)).to be true
    end
  end
end
