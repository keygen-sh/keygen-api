class SerializableBase < JSONAPI::Serializable::Resource
  id { @object.hashid }
end
