# frozen_string_literal: true

# FIXME(ezekg) This is incredibly hacky, but since our keys can get quite
#              large due to cryptographic signatures, this limits key search
#              space to the first 128 chars.
class PgSearch::Configuration::Column
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