class FindByAliasService < BaseService
  PRIMARY_KEY = :id

  def initialize(scope, id:, aliases:, reorder: true)
    @table   = scope.respond_to?(:table_name) ? scope.table_name : scope.class.table_name
    @model   = scope.model_name.name
    @scope   = scope
    @id      = id.to_s
    @aliases = aliases
    @reorder = reorder
  end

  def call = find_by_alias!

  private

  attr_reader :table,
              :model,
              :scope,
              :id,
              :aliases,
              :reorder

  def reorder? = !!reorder

  def find_by_alias!
    raise Keygen::Error::NotFoundError.new(model:, id:) if
      id.blank?

    # strip out ID attribute if the ID doesn't resemble a UUID (pg will throw)
    columns = [PRIMARY_KEY, *aliases].uniq

    columns.reject! { _1 == PRIMARY_KEY } unless
      UUID_RE.match?(id)

    raise Keygen::Error::NotFoundError.new(model:, id:) if
      columns.empty?

    # generates a query resembling the following while handling encrypted columns:
    #
    #   SELECT
    #     "accounts".*
    #   FROM
    #     "accounts"
    #   WHERE
    #     "accounts"."id"   = :id OR
    #     "accounts"."slug" = :id
    #   LIMIT
    #     1
    #
    primary_column, *alias_columns = columns

    scp = scope.where(primary_column => id)
    scp = alias_columns&.reduce(scp) do |s, column|
      s.or(
        scope.where(column => id),
      )
    end

    # find the oldest one first in case of duplicates
    scp = scp.reorder("#{table}.created_at ASC") if
      reorder?

    record = scp.limit(1)
                .take

    raise Keygen::Error::NotFoundError.new(model:, id:) if
      record.nil?

    record
  end
end
