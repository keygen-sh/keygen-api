# frozen_string_literal: true

FactoryBot.define do
  factory :release_arch, aliases: %i[arch] do
    sequence :key, %w[386 amd64 arm arm64 mips mips64 mips64le mipsle ppc64 ppc64le s390x].cycle

    account { nil }
  end
end
