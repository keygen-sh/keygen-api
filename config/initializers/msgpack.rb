# frozen_string_literal: true

MessagePack::DefaultFactory.register_type(0x01, ActiveSupport::TimeWithZone,
  packer: -> t { t.iso8601(6).to_msgpack },
  unpacker: -> t { Time.parse(MessagePack.unpack(t)) },
)

MessagePack::DefaultFactory.register_type(0x02, Time,
  packer: -> t { t.iso8601(6).to_msgpack },
  unpacker: -> t { Time.parse(MessagePack.unpack(t)) },
)

MessagePack::DefaultFactory.register_type(0x03, Date,
  packer: -> d { d.to_s.to_msgpack },
  unpacker: -> d { Date.parse(MessagePack.unpack(d)) },
)
