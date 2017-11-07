class EnablePgStatsExtension < ActiveRecord::Migration[5.0]
  def change
    enable_extension "pg_stat_statements"
  end
end
