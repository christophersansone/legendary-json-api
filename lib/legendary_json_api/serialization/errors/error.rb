module LegendaryJsonApi
  module Serialization
    module Errors
      class Error

        def self.serialize(error)
          return { detail: error.message }
        end
      end
    end
  end
end
