# frozen_string_literal: true

module TemporaryTables
  module Methods
    extend ActiveSupport::Concern

    class_methods do
      def temporary_table(name, ...)
        table_name = name.to_s.pluralize

        before do
          ActiveRecord::Migration.suppress_messages do
            ActiveRecord::Migration.create_table(table_name, ...)
          end
        end

        after do
          ActiveRecord::Migration.suppress_messages do
            ActiveRecord::Migration.drop_table(table_name, if_exists: true)
          end
        end
      end

      def temporary_model(name, table_name: name.to_s.pluralize, base_class: ActiveRecord::Base, &extension)
        class_name = name.to_s.classify

        before do
          klass = Class.new *base_class do
                    define_method(:table_name) { table_name } unless table_name.nil?
                    define_method(:name)       { class_name }
                  end

          unless extension.nil?
            klass.class_eval(&extension)
          end

          stub_const(class_name, klass)
        end
      end
    end
  end
end
