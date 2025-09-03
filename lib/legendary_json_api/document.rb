module LegendaryJsonApi
  class Document

    # Builds the output that adheres to our Open API specification

    class << self

      def render(data: nil, included: [], errors: nil, meta: {}, links: [])
        raise "Cannot have both data and errors" if data && errors

        response = {}
        response[:errors] = errors if errors
        response[:data] = data if !errors
        response[:included] = included if included.present?
        response[:links] = links if links.present?
        response[:meta] = meta if meta
        return response
      end

      def render_model(model, included: [], serializer: nil, params: nil, meta: {})
        serializer ||= resolve_serializer(model)
        ensure_eager_loading!(model, included, serializer) if model.is_a?(ActiveRecord::Base)
        data = serializer.serialize(model, params: params, included: included)
        included_data = included.present? ? serializer.serialize_included(model, included: included, params: params) : []
        render(data: data, included: included_data, meta: meta)
      end

      def render_models(models, included: [], serializer: nil, params: nil, meta: {})
        ensure_eager_loading!(models, included, serializer) if models.is_a?(ActiveRecord::Relation)
        data = []
        included_list = Serialization::IncludedList.new
        models.each do |model|
          model_serializer = serializer || resolve_serializer(model)
          data.push(model_serializer.serialize(model, params: params, included: included))
          model_serializer.serialize_included(model, included: included, params: params, included_list: included_list) if included.present?
        end

        render(data: data, included: included_list.to_a, meta: meta)
      end

      def render_exception(e)
        if e.is_a?(ActiveRecord::RecordNotFound)
          errors = Serialization::Errors::RecordNotFound.serialize(e)
        elsif e.is_a?(ActiveRecord::RecordInvalid)
          errors = Serialization::Errors::RecordInvalid.serialize(e)
        else
          errors = Serialization::Errors::Error.serialize(e)
        end
        render(errors: errors)
      end

      protected

      def ensure_eager_loading!(models, included, serializer)
        Serialization::EagerLoader.eager_load!(models, included, serializer)
      end

      def resolve_serializer(model)
        Serialization::Resolver.resolve(model)
      end
    end
  end
end
