# frozen_string_literal: true

module FileHelper
  module ScenarioMethods
    def with_file(path:, content: nil, fixture: nil, &)
      p = if (p = Pathname.new(path)) && p.relative?
            Rails.root.join(p)
          else
            path
          end
      v = if fixture.present?
            file_fixture(fixture).read
          else
            content
          end

      context "with file #{path.inspect}" do
        before do
          allow(File).to receive(:read).with(p).and_return(v || '')
        end

        instance_exec(&)
      end
    end

    def file_fixture(fixture)
      filename = Rails.root / "spec/fixtures/files" / fixture

      Pathname.new(filename)
    end
  end

  def self.included(klass)
    klass.extend ScenarioMethods
  end
end
