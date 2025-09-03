module LegendaryJsonApi
  module Serialization

    # Just a simple indexed list of included objects and their serialized values
    # to prevent redundant serializations of the same objects
    class IncludedList

      def initialize
        @hash = {}
      end

      def add(object, serialized)
        @hash[object] = serialized
      end

      def exists?(object)
        @hash.has_key?(object)
      end

      def [](object)
        @hash[object]
      end

      def to_a
        @hash.values
      end

    end
  end
end