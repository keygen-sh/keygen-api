# frozen_string_literal: true

module PgSearch
  class ScopeOptions
    def apply(scope)
      scope = include_table_aliasing_for_rank(scope)
      rank_table_alias = scope.pg_search_rank_table_alias(:include_counter)

      scope
        .joins(rank_join(rank_table_alias))
        .extend(WithPgSearchRank)
        .extend(WithPgSearchHighlight[feature_for(:tsearch)])
    end

    def subquery
      model
        # FIXME(ezekg) PgSearch and ActiveRecord don't play well together when
        #              a table gets aliased e.g. `roles` => `roles_users` so
        #              this removes the top-level scopes altogether since it's
        #              a subquery and the scopes will be applied outside of the
        #              search scope. This is taken from latest PgSearch.
        .unscoped
        .select("#{primary_key} AS pg_search_id")
        .select("#{rank} AS rank")
        .joins(subquery_join)
        .where(conditions)
        .reorder('rank DESC')
        .limit(nil)
        .offset(nil)
    end
  end

  # FIXME(ezekg) This is incredibly hacky, but since our keys can get quite
  #              large due to cryptographic signatures, this limits key search
  #              space to the first 128 chars. We're also making email tokenization
  #              more usable by allowing searches by domain name.
  class Configuration::Column
    def to_sql
      if "#{table_name}.#{column_name}" == '"machines"."fingerprint"' ||
         "#{table_name}.#{column_name}" == '"licenses"."key"' ||
         "#{table_name}.#{column_name}" == '"keys"."key"'
        "\"left\"(coalesce(#{expression}::text, ''), 128)"
      elsif "#{table_name}.#{column_name}" == '"users"."email"'
        "\"replace\"(coalesce(#{expression}::text, ''), '@', ' ')"
      else
        "coalesce(#{expression}::text, '')"
      end
    end
  end
end