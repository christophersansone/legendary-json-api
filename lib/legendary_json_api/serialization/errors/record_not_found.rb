module LegendaryJsonApi
  module Serialization
    module Errors
      class RecordNotFound < Error

        def self.serialize(error)
          raise "Invalid error type: #{error.class}" unless error.is_a?(ActiveRecord::RecordNotFound)
          return [{ status: 404, title: 'Not Found', detail: 'The specified resource does not exist' }]
        end
      end
    end
  end
end
