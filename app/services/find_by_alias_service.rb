class FindByAliasService < BaseService
  def initialize(scope:, identifier:, aliases:, reorder: true)
    @table_name = scope.respond_to?(:table_name) ? scope.table_name : scope.class.table_name
    @model_name = scope.model_name.name
    @scope = scope
    @identifier = identifier&.squish
    @aliases = aliases
    @reorder = reorder
  end

  def call
    find_by_alias!
  end

  private

  attr_reader :table_name
  attr_reader :model_name
  attr_reader :scope
  attr_reader :identifier
  attr_reader :aliases
  attr_reader :reorder

  def find_by_alias!
    raise Keygen::Error::NotFoundError.new(model: model_name, id: identifier) if identifier.nil?

    # Strip out ID attribute if the finder doesn't resemble a UUID (pg will throw)
    columns = [:id, *aliases].uniq
    columns.reject! { |c| c == :id } unless identifier =~ UUID_RE
    if columns.empty?
      raise Keygen::Error::NotFoundError.new(model: model_name, id: identifier)
    end

    # Generates a query resembling the following:
    #
    #   SELECT
    #     "accounts".*
    #   FROM
    #     "accounts"
    #   WHERE
    #     "accounts"."id"   = :identifier OR
    #     "accounts"."slug" = :identifier
    #   LIMIT
    #     1
    s = scope.where(
      columns.map { |c| "#{Arel.sql("\"#{table_name}\".\"#{c}\"")} = :identifier" }.join(" OR "),
      identifier: identifier
    )

    # In case of duplicates, find the oldest one first.
    s = s.reorder(created_at: :asc) if
      reorder?

    record = s.limit(1)
              .take

    if record.nil?
      raise Keygen::Error::NotFoundError.new(model: model_name, id: identifier)
    end

    record
  end

  private

  def reorder?
    reorder
  end
end
