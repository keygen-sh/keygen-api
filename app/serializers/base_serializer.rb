class BaseSerializer < ActiveModel::Serializer
  cache

  def id
    object.hashid
  end

  def created
    object.created_at
  end

  def updated
    object.updated_at
  end

  protected

  attr_writer :type

  def type(t)
    @type = t.to_s
  end
end
