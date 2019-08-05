# frozen_string_literal: true

module PgSearch
  # Adjust pg_search to accept a block to fine-tune a search's subquery
  # See: https://github.com/Casecommons/pg_search/issues/292
  module ClassMethods
    def pg_search_scope(name, options)
      options_proc = if options.respond_to?(:call)
                       options
                     else
                       raise ArgumentError, "pg_search_scope expects a Hash or Proc" unless options.respond_to?(:merge)
                       ->(query) { {:query => query}.merge(options) }
                     end

      define_singleton_method(name) do |*args, &block|
        config = Configuration.new(options_proc.call(*args), self)
        scope_options = ScopeOptions.new(config)
        scope_options.apply(self, &block)
      end
    end
  end

  class ScopeOptions
    def apply(scope, &block)
      scope = include_table_aliasing_for_rank(scope)
      rank_table_alias = scope.pg_search_rank_table_alias(:include_counter)

      scope
        .joins(rank_join(rank_table_alias, &block))
        .order(Arel.sql("#{rank_table_alias}.rank DESC, #{order_within_rank}"))
        .extend(DisableEagerLoading)
        .extend(WithPgSearchRank)
        .extend(WithPgSearchHighlight[feature_for(:tsearch)])
    end

    def subquery
      relation = model
        .unscoped
        .select("#{primary_key} AS pg_search_id")
        .select("#{rank} AS rank")
        .joins(subquery_join)
        .where(conditions)
        .limit(nil)
        .offset(nil)

      block_given? ? yield(relation) : relation
    end

    def rank_join(rank_table_alias, &block)
      "INNER JOIN (#{subquery(&block).to_sql}) AS #{rank_table_alias} ON #{primary_key} = #{rank_table_alias}.pg_search_id"
    end
  end

  # FIXME(ezekg) This is incredibly hacky, but since our keys can get quite
  #              large due to cryptographic signatures, this limits key search
  #              space to the first 128 chars.
  class Configuration::Column
    def to_sql
      if "#{table_name}.#{column_name}" == '"machines"."fingerprint"' ||
         "#{table_name}.#{column_name}" == '"licenses"."key"' ||
         "#{table_name}.#{column_name}" == '"keys"."key"'
        "\"left\"(coalesce(#{expression}::text, ''), 128)"
      else
        "coalesce(#{expression}::text, '')"
      end
    end
  end
end