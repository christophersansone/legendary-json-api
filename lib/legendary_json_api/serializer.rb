module LegendaryJsonApi

  # Provides a DSL to describe how a class (e.g. model) should be serialized,
  # and provides methods to perform the serialization of itself and its related records

  class Serializer

    def self.serialize(model, params: {}, included: [])
      output = { type: type, id: Config.transform_id(id_for(model)) }

      if attribute_definitions.present?
        attributes = {}
        attribute_definitions.each_pair do |name, attr|
          if attr.serialize?(model, params)
            key = Config.transform_key(name)
            value = attr.serialize(model, params)
            attributes[key] = value
          end
        end
        output[:attributes] = attributes
      end


      if relationship_definitions.present?
        relationships = {}
        relationship_definitions.each_pair do |name, rel|
          include_rel = included.include?(name)
          if rel.serialize?(model, params: params, included: include_rel)
            key = Config.transform_key(name)
            value = rel.serialize(model, params: params, included: include_rel)
            relationships[key] = value
          end
        end
        output[:relationships] = relationships if relationships.length
      end

      return output
    end

    def self.serialize_included(model, included: nil, params: {}, included_list: nil)
      if included.present?
        included_list ||= Serialization::IncludedList.new

        if included.is_a?(Symbol)
          name = included
          relationship_definition = find_relationship!(name)
          if relationship_definition.serialize_included?(model, params: params)
            relationship_definition.serialize_included(model, params: params, included_children: nil, included_list: included_list)
          end

        elsif included.is_a?(Array)
          included.each { |i| serialize_included(model, included: i, params: params, included_list: included_list) }

        elsif included.is_a?(Hash)
          included.each_pair do |name, children|
            relationship_definition = find_relationship!(name)
            if relationship_definition.serialize_included?(model, params: params)
              relationship_definition.serialize_included(model, params: params, included_children: children, included_list: included_list)
            end
          end
        end
      end

      # return the array of serialized included objects
      return included_list ? included_list.to_a : []
    end

    def self.id_for(model, params = {})
      if @id_definition
        return execute_proc(@id_definition, model, params) if @id_definition.is_a?(Proc)
        return model.public_send(@id_definition)
      end

      return model.public_send(model.class.primary_key) if model.is_a?(ActiveRecord::Base)
      return model.id
    end

    def self.execute_proc(method, *args)
      arity = method.arity.abs
      args_to_send = args.take(arity)
      return method.call(*args_to_send)
    end


    # DSL
    class << self
      def type(value = nil)
        # provide both a getter a setter
        @type_key = value.to_s if value.present?
        @type_key ||= name.gsub(/Serializer$/, '').underscore
      end

      def id(value = nil)
        @id_definition = value if value.present?
        @id_definition
      end

      def attribute(name, if: nil, &block)
        attribute_definitions[name] ||= Serialization::Attribute.new(
          name,
          method: block || name,
          if: binding.local_variable_get(:'if')
        )
      end

      def attributes(*names)
        names.each { |name| attribute(name) }
      end

      def belongs_to(name, method: nil, association_name: nil, serializer: nil, link: nil, force_data: false, if: nil, &block)
        relationship_definitions[name] ||= Serialization::Relationship::BelongsTo.new(
          name,
          association_name: association_name,
          method: method || block,
          serializer: serializer,
          link: link,
          force_data: force_data,
          if: binding.local_variable_get(:'if')
        )
      end

      def has_one(name, method: nil, association_name: nil, serializer: nil, link: nil, force_data: false, if: nil, &block)
        relationship_definitions[name] ||= Serialization::Relationship::HasOne.new(
          name,
          association_name: association_name,
          method: method || block,
          serializer: serializer,
          link: link,
          force_data: force_data,
          if: binding.local_variable_get(:'if')
        )
      end

      def has_many(name, method: nil, association_name: nil, serializer: nil, link: nil, force_data: false, if: nil, &block)
        relationship_definitions[name] ||= Serialization::Relationship::HasMany.new(
          name,
          association_name: association_name,
          method: method || block,
          serializer: serializer,
          link: link,
          force_data: force_data,
          if: binding.local_variable_get(:'if')
        )
      end

      def attribute_definitions
        return @attribute_definitions if @attribute_definitions
        # inherit from the parents, but make a copy to keep a unique list for this class
        return @attribute_definitions = superclass.attribute_definitions.dup if superclass.respond_to?(:attribute_definitions)
        @attribute_definitions = {}
      end

      def relationship_definitions
        return @relationship_definitions if @relationship_definitions
        # inherit from the parents, but make a copy to keep a unique list for this class
        return @relationship_definitions = superclass.relationship_definitions.dup if superclass.respond_to?(:relationship_definitions)
        @relationship_definitions = {}
      end

      protected
      
      def find_relationship!(name)
        result = relationship_definitions[name]
        return result if result.present?
        raise "Relationship '#{name}' not found on #{self.name}"
      end
    end
  end
end
