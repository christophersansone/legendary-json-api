module LegendaryJsonApi
  module Serialization
    module Relationship

      class Base
        attr_reader :name, :method, :association_name, :serializer, :link, :force_data, :conditional_proc

        def initialize(name, method: nil, association_name: nil, serializer: nil, link: nil, force_data: false, if: nil)
          # name of the key to output
          @name = name
          @method = method
          # name of the (ActiveRecord) association to reference on the model
          @association_name = association_name
          @serializer = (serializer.is_a?(Proc) ? serializer : Resolver.resolve(serializer)) if serializer
          @link = link
          @force_data = force_data
          @conditional_proc = binding.local_variable_get(:'if')
        end

        def serialize(record, params: nil, included: false)
          # get the link hash if specified
          serialized_link = serialize_link(record, params) if link
          # determine if the reference should be serialized
          serialize_reference = !serialized_link || included || force_data?(record, params)
          if serialize_reference
            # get the data hash
            serialize_by_record = included || requires_record?
            serialized_reference = serialize_by_record ? serialize_reference_by_related_record(record, params) : serialize_reference_by_id(record, params)
          end
          # return the result based on merging or returning the link and data hashes
          return serialized_link.merge(serialized_reference) if serialized_link && serialized_reference
          return serialized_link || serialized_reference
        end

        def serialize_included(record, params: nil, included_children: nil, included_list: nil)
          related_record = related_record_for(record, params)
          return unless related_record.present?

          related_serializer = serializer || Resolver.resolve(related_record)
          if !included_list.exists?(related_record)
            serialized_related_record = related_serializer.serialize(related_record, params: params)
            included_list.add(related_record, serialized_related_record)
          end

          if included_children.present?
            related_serializer.serialize_included(related_record, params: params, included: included_children, included_list: included_list)
          end

          included_list
        end

        def serialize?(record, params: nil, included: false)
          return Serializer.execute_proc(conditional_proc, record, params) if conditional_proc
          return true
        end

        def serialize_included?(record, params: nil)
          serialize?(record, params: params, included: true)
        end

        def klass_association_for(klass)
          association = association_name || (method if !method.is_a?(Proc)) || name
          return klass.reflect_on_association(association) if association
        end

        protected

        def requires_record?
          method.is_a?(Proc) || serializer.is_a?(Proc)
        end

        def force_data?(record, params)
          return Serializer.execute_proc(force_data, record, params) if force_data.is_a?(Proc)
          return !!force_data
        end

        def serialize_link(record, params)
          value = link.is_a?(Proc) ? Serializer.execute_proc(link, record, params) : link
          { links: { related: value } } unless value.nil?
        end

        def serialize_reference_by_related_record(record, params)
          raise NotImplementedError
        end

        def serialize_reference_by_id(record, params)
          raise NotImplementedError
        end

        
        def association_for(record)
          return unless record.is_a?(ActiveRecord::Base)
          @associations ||= {}
          klass = record.class
          result = @associations[klass]
          return result if result || @associations.has_key?(klass)
          @associations[klass] = klass_association_for(klass)
        end

        def serialize_reference(type, id)
          { type: type.to_s, id: Config.transform_id(id) }
        end

        def resolve_serializer(record, params)
          return Resolver.resolve_dynamic(serializer, record, params) if serializer.is_a?(Proc)
          return serializer || Resolver.resolve(record)
        end
      end
    end
  end
end
