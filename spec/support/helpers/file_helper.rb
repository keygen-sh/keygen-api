# frozen_string_literal: true

module FileHelper
  module ClassMethods
    def with_file(filename:, content: nil, fixture: nil)
      before do
        v = if fixture.present?
              file_fixture(fixture).read
            else
              content
            end

        allow(File).to receive(:read).with(filename).and_return(v || '')
      end

      yield
    end
  end

  def self.included(klass)
    klass.extend ClassMethods
  end
end
