module LegendaryJsonApi
  module Serialization
    module Relationship
      class HasMany < Base

        # Has Many relationships will not output anything if there is no link, data is not expliclity included via :force_data,
        # and the relationship is not being included. In other words, unlike :belongs_to and :has_one, has many will default to
        # NOT output anything unless specified one way or another.

        def serialize?(record, params: nil, included: false)
          # check the conditional proc -- do not serialize if false
          return false if conditional_proc && !Serializer.execute_proc(conditional_proc, record, params)
          # allow links at all times
          return true if link
          # allow if force_data
          return true if force_data?(record, params)
          # has many relationship data should only be serialized if included -- if not, do not even output the relationship
          return false if !included
          return true
        end

        def serialize(record, params: nil, included: false)
          # get the link hash if specified
          serialized_link = serialize_link(record, params) if link
          # serialize the references if it is being included or if explicitly stated
          serialize_reference = included || force_data?(record, params)
          # get the data hash
          serialized_reference = serialize_reference_by_related_records(record, params) if serialize_reference
          # return the result based on merging or returning the link and data hashes
          return serialized_link.merge(serialized_reference) if serialized_link && serialized_reference
          return serialized_link || serialized_reference
        end

        def serialize_included?(record, params: nil)
          return Serializer.execute_proc(conditional_proc, record, params) if conditional_proc
          return true
        end

        def serialize_included(record, params: nil, included_children: nil, included_list: nil)
          related_records = related_records_for(record, params)
          related_records.each do |r|
            related_serializer = resolve_serializer(r, params)

            if !included_list.exists?(r)
              included_list.add(r, related_serializer.serialize(r, params: params))
            end

            if included_children
              related_serializer.serialize_included(r, params: params, included: included_children, included_list: included_list)
            end
          end

          included_list
        end

        protected

        def related_records_for(record, params)
          return Serializer.execute_proc(method, record, params) if method.is_a?(Proc)
          return record.public_send(association_name) if association_name
          return record.public_send(method) if method
          return record.public_send(name)
        end

        def serialize_reference_by_related_records(record, params)
          related_records = related_records_for(record, params)
          serialized = related_records.to_a.map do |r|
            related_serializer = resolve_serializer(r, params)
            serialize_reference(related_serializer.type, related_serializer.id_for(r, params))
          end
          { data: serialized }
        end
      end
    end
  end
end
