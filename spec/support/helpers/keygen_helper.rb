# frozen_string_literal: true

module KeygenHelper
  module ClassMethods
    def within_ee(expiry: 1.year.from_now.iso8601, issued: 1.day.ago.iso8601, entitlements: %i[request_logs event_logs permissions environments], &block)
      context 'when in an EE context' do
        before do
          allow(Keygen).to receive(:ce?).and_return false
          allow(Keygen).to receive(:ee?).and_return true
          allow(Keygen::EE::LicenseFile).to receive(:current).and_return(
            Keygen::EE::LicenseFile.new(
              included: entitlements.map {{ type: 'entitlements', attributes: { code: _1.to_s.upcase } }},
              data: { type: 'licenses', attributes: { expiry: } },
              meta: { issued:, expiry: },
            ),
          )
        end

        instance_exec(&block)
      end
    end

    def within_ce(&)
      context 'when in a CE context' do
        before do
          allow(Keygen).to receive(:ce?).and_return true
          allow(Keygen).to receive(:ee?).and_return false
        end

        instance_exec(&)
      end
    end
  end

  def self.included(klass)
    klass.extend ClassMethods
  end
end
