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

        before do |example|
          klass = Class.new *base_class do
                    define_singleton_method(:table_name) { table_name } unless table_name.nil?
                    define_singleton_method(:name)       { class_name }
                  end

          unless extension.nil?
            # pass in an example context so that vars can be accessed
            context = Class.new do
                        define_method(:respond_to_missing?) do |method_name|
                          example.instance_exec { respond_to?(method_name) }
                        end

                        define_method(:method_missing) do |method_name|
                          example.instance_exec { send(method_name) }
                        end
                      end

            klass.module_exec(context.new, &extension)
          end

          stub_const(class_name, klass)
        end
      end
    end
  end
end
