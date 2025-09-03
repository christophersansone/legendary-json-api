module LegendaryJsonApi
  module Serialization
    module Errors
      class RecordInvalid < Error

        def self.serialize(error)
          raise "Invalid error type: #{error.class}" unless error.is_a?(ActiveRecord::RecordInvalid)

          result = []
          errors_hash = error.record.errors.to_hash
          errors_hash.each_pair do |key, key_errors|
            key_errors.each do |e|
              result.push({ status: 422, detail: e, source: { pointer: "/data/attributes/#{Config.transform_key(key)}" } })
            end
          end
          result
        end
      end
    end
  end
end
