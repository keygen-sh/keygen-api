class FindByAliasService < BaseService
  def initialize(scope:, identifier:, aliases:, reorder: true)
    @table_name  = scope.respond_to?(:table_name) ? scope.table_name : scope.class.table_name
    @model_name  = scope.model_name.name
    @model_scope = scope
    @identifier  = identifier&.squish
    @aliases     = aliases
    @reorder     = reorder
  end

  def call = find_by_alias!

  private

  attr_reader :table_name,
              :model_name,
              :model_scope,
              :identifier,
              :aliases,
              :reorder

  def reorder? = !!reorder

  def find_by_alias!
    raise Keygen::Error::NotFoundError.new(model: model_name, id: identifier) if
      identifier.nil?

    # Strip out ID attribute if the identifier doesn't resemble a UUID (pg will throw)
    columns = [:id, *aliases].uniq

    columns.reject! { _1 == :id } unless
      UUID_RE.match?(identifier)

    raise Keygen::Error::NotFoundError.new(model: model_name, id: identifier) if
      columns.empty?

    # Generates a query resembling the following, while handling encrypted columns:
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
    primary_column, *alias_columns = columns

    scope = model_scope.where(primary_column => identifier)
    scope = alias_columns&.reduce(scope) do |s, column|
      s.or(
        model_scope.where(column => identifier),
      )
    end

    # In case of duplicates, find the oldest one first.
    scope = scope.reorder(created_at: :asc) if
      reorder?

    record = scope.limit(1)
                  .take

    raise Keygen::Error::NotFoundError.new(model: model_name, id: identifier) if
      record.nil?

    record
  end
end
