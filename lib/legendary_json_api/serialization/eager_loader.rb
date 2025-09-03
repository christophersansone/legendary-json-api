module LegendaryJsonApi
  module Serialization

    # Automatically eager load the relationships defined as the serializer :included directive
    # to avoid n+1 queries during serialization

    class EagerLoader

      class << self

        def eager_load!(models, included, serializer = nil)
          return eager_load_relation!(models, included, serializer) if models.is_a?(ActiveRecord::Relation)
          return eager_load_model_associations!(models, included, serializer) if models.is_a?(ActiveRecord::Base)
          raise "Cannot eager load class #{models.class.inspect}"
        end

        protected

        def eager_load_relation!(relation, included, serializer)
          return relation if relation.loaded?
          # enforce strict loading to guarantee no n+1 queries during serialization
          relation.strict_loading!
          # attempt to identify any relationships to automatically include
          include_relationships = IncludesResolver.resolve(relation.klass, included, serializer)
          preload_associations(relation, include_relationships)
          relation
        end

        def eager_load_model_associations!(model, included, serializer)
          include_relationships = IncludesResolver.resolve(model.class, included, serializer)
          preload_associations(model, include_relationships)
          model
        end

        # calling relation.includes(...) will create a new relation,
        # but instead we want to preload the actual relation on the model to avoid any subsequent calls to it.
        # This is more of a private Rails API, but it's the right way to do it because it's the only way
        def preload_associations(models, associations)
          records = models.is_a?(ActiveRecord::Base) ? [models] : models
          ActiveRecord::Associations::Preloader.new(records: records, associations: associations).call
        end

      end
    end
  end
end
