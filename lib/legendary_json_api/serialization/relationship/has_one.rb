module LegendaryJsonApi
  module Serialization
    module Relationship
      # currently, :has_one acts identical to :belongs_to
      class HasOne < BelongsTo

        protected

        # has one must always fetch the record because the ID cannot otherwise be determined
        def requires_record?
          true
        end

      end
    end
  end
end
