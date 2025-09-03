module LegendaryJsonApi
  module Serialization
    module Relationship

      # By default, it will return the appropriate data reference object.
      # If :link is specified, it will return the related link and not include the data.
      # To output both a link and data, set :force_data to true.
      class BelongsTo < Base

        protected

        def serialize_reference_by_related_record(record, params)
          related_record = related_record_for(record, params)
          return { data: nil } unless related_record
          related_serializer = resolve_serializer(related_record, params)
          serialized = serialize_reference(related_serializer.type, related_serializer.id_for(related_record, params))
          return { data: serialized }
        end

        def related_record_for(record, params)
          return Serializer.execute_proc(method, record, params) if method.is_a?(Proc)
          return record.public_send(association_name) if association_name
          return record.public_send(method) if method
          return record.public_send(name)
        end

        def serialize_reference_by_id(record, params)
          association = association_for(record)

          if association.is_a?(ActiveRecord::Reflection::BelongsToReflection)
            return serialize_belongs_to_association(record, params, association)
          end

          return serialize_reference_by_related_record(record, params)
        end

        def serialize_belongs_to_association(record, params, association)
          id = record.public_send(association.foreign_key)
          return { data: nil } unless id

          if association.polymorphic?
            foreign_type = record.public_send(association.foreign_type).constantize
          else
            foreign_type = association.klass
          end
          related_serializer = serializer || Resolver.resolve(foreign_type)
          serialized = serialize_reference(related_serializer.type, id) 
          return { data: serialized }
        end
      end
    end
  end
end
