require 'rails_helper'

describe LegendaryJsonApi::Serialization::Relationship::HasOne do
  it 'works just like the belongs to relationship' do
    expect(LegendaryJsonApi::Serialization::Relationship::HasOne.superclass).to eq LegendaryJsonApi::Serialization::Relationship::BelongsTo
  end
end
