module LegendaryJsonApi
  module Serialization
    class Attribute
      attr_reader :name, :method, :conditional_proc

      def initialize(name, method: nil, if: nil)
        @name = name
        @method = method || name
        @conditional_proc = binding.local_variable_get(:'if')
      end

      def serialize(record, params)
        if method.is_a?(Proc)
          Serializer.execute_proc(method, record, params)
        else
          record.public_send(method)
        end
      end

      def serialize?(record, params)
        if conditional_proc.present?
          Serializer.execute_proc(conditional_proc, record, params)
        else
          true
        end
      end
    end

  end
end
