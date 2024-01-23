# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe ReleaseDownloadLink, type: :model do
  let(:account) { create(:account) }

  it_behaves_like :environmental
  it_behaves_like :encryptable
end
