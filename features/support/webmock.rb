# frozen_string_literal: true

require 'webmock/cucumber'

# allow clickhouse connections (uses HTTP as its wire protocol)
WebMock.disable_net_connect!(allow: 'localhost:8123')
