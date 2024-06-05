# frozen_string_literal: true

FactoryBot.define do
  factory :release_arch, aliases: %i[arch] do
    initialize_with { new(**attributes.reject { NIL_ACCOUNT == _2 }) }

    sequence :key, %w[386 amd64 arm arm64 mips mips64 mips64le mipsle ppc64 ppc64le s390x].cycle

    account { NIL_ACCOUNT }
  end
end
