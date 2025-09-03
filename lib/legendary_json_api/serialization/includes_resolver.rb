module LegendaryJsonApi
  module Serialization

    # Converts a serializer :included directive into the value to pass into relation.includes()
    # to automatically mitigate most n+1 query attempts

    class IncludesResolver

      class << self

        def resolve(model_klass, included, serializer = nil)
          serializer ||= resolve_serializer(model_klass)

          # because resolution is deterministic, cache unique calls to this method to avoid repetition
          @includes ||= {}
          cache_key = [ model_klass.name, included.inspect, serializer.name ].join(':')
          @includes[cache_key] ||= resolve_includes(model_klass, included, serializer) || []
        end

        protected

        def compact_included(included, aggregated = {})
          return aggregated if included.blank?

          if included.is_a?(Symbol)
            aggregated[included] ||= {}
            return aggregated
          end

          if included.is_a?(Array)
            included.each { |i| compact_included(i, aggregated) }
            return aggregated
          end

          if included.is_a?(Hash)
            included.each_pair do |key, children|
              aggregated[key] ||= {}
              compact_included(children, aggregated[key])
            end
            return aggregated
          end

          raise "Unexpected included value #{included.inspect}"
        end

        def reduce_included(included)
          compacted = compact_included(included)
          result = []
          compacted.each_pair do |key, children|
            reduced_children = reduce_included(children) if children.present?
            if reduced_children.present?
              result.push({ key => reduced_children })
            else
              result.push(key)
            end
          end
          return result
        end

        def resolve_includes(klass, included, serializer = nil)
          serializer ||= resolve_serializer(klass)
          compacted = compact_included(included)
          result = resolve_serializer_relationships(klass, compacted, serializer)
          reduce_included(result)
        end

        def resolve_serializer(model)
          Resolver.resolve(model)
        end

        # On the surface, it seems easier to just go through the list of included,
        # but there can still be other n+1 queries for records that are not included,
        # such as has_one relationships.
        def resolve_serializer_relationships(klass, included, serializer)
          result = {}
          serializer.relationship_definitions.each_pair do |name, relationship|
            association = relationship.klass_association_for(klass)
            if association && should_include_association?(association, name, relationship, included)
              # include this relationship and recursively include its children
              if association.polymorphic?
                # polymorphic associations cannot resolve the class, determine the serializer, or load child relationships --
                # add the relationship but not its children
                result[name] = {}
              else
                children = included[name]
                result[name] = resolve(association.klass, children, relationship.serializer)
              end
            end
          end
          result
        end

        def should_include_association?(association, relationship_name, relationship, included)
          # include the association if the record should be output in the :included array
          return true if included.has_key?(relationship_name)
          # has_one relationships require a fetch to resolve (as opposed to a foreign key with a belongs_to)
          return true if association.is_a?(ActiveRecord::Reflection::HasOneReflection)
          # include the association if the relationship states that data should be included --
          # even if force_data is a Proc, assume it should be included since it has the potential to
          return true if relationship.force_data
          # if it made it this far, it does not need to be included
          return false
        end

      end
    end
  end
end
