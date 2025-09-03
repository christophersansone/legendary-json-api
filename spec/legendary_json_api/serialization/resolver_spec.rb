require 'rails_helper'

RSpec.describe LegendaryJsonApi::Serialization::Resolver do

  let(:resolver) { described_class }

  describe '#resolve' do
    describe 'when a symbol is specified' do
      it 'returns the serializer associated with the type identified by the symbol' do
        expect(resolver.resolve(:user)).to eq UserSerializer
      end

      it 'fails if the type is not associated with a symbol' do
        expect { resolver.resolve(:homer) }.to raise_exception(StandardError)
      end
    end

    describe 'when a serializer class is specified' do
      it 'returns the serializer class' do
        expect(resolver.resolve(UserSerializer)).to eq UserSerializer
      end
    end

    describe 'when a model class is specified' do
      it 'returns the serializer class' do
        expect(resolver.resolve(User)).to eq UserSerializer
      end
    end

    describe 'when a model is specified' do
      it 'returns the serializer class associated with the model class' do
        organization = Organization.create!(name: 'The Simpsons')
        model = User.create!(first_name: 'Homer', last_name: 'Simpson', email: 'homer@simpsons.com', organization: organization)
        expect(resolver.resolve(model)).to eq UserSerializer
      end
    end
  end
end
