module LegendaryJsonApi
  module Serialization

    # Determines the serializer to use for the given value (symbol, model class, etc.)

    class Resolver

      class << self

        def resolve(value)
          @cache ||= {}
          return value if value.is_a?(Class) && value.ancestors.include?(Serializer)
          return resolve_by_symbol(value) if value.is_a?(Symbol)
          return resolve_by_model_class(value) if value.is_a?(Class) && value.ancestors.include?(ActiveRecord::Base)
          return resolve_by_model_class(value.model) if value.is_a?(ActiveRecord::Relation)
          
          raise "Cannot statically resolve a proc. Call #resolve_dynamic with the model instead." if value.is_a?(Proc)

          return resolve_by_model(value)
        end

        def resolve_dynamic(method, model, params)
          value = Serializer.execute_proc(method, model, params)
          resolve(value)
        end

        protected

        def resolve_by_symbol(value)
          @cache[value] ||= "#{value.to_s.classify}Serializer".constantize
        end

        def resolve_by_model(value)
          resolve_by_model_class(value.class)
        end

        def resolve_by_model_class(value)
          begin
            @cache[value] ||= "#{value.name}Serializer".constantize
          rescue NameError => e
            if value.ancestors.include?(ActiveRecord::Base)
              resolve_by_model_class(value.superclass)
            else
              raise e
            end
          end
        end
      end
    end
  end
end
