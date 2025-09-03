require 'rails_helper'

describe LegendaryJsonApi::Serialization::Attribute do

  let(:resolver) { described_class }
  let(:organization) { Organization.create!(name: 'The Simpsons') }
  let(:model) { User.create!(first_name: 'Homer', last_name: 'Simpson', email: 'homer@simpsons.com', organization: organization) }
  let(:params) { {} }

  describe 'when only the name is specified' do
    it 'outputs the value of the name' do
      attr = described_class.new(:first_name)
      expect(attr.serialize(model, params)).to eq model.first_name
    end
  end

  describe 'when a method is specified' do

    describe 'when a method name is specified' do
      it 'executes the method name on the model and outputs the value' do
        attr = described_class.new(:blah, method: :last_name)
        expect(attr.serialize(model, params)).to eq model.last_name
      end
    end

    describe 'when a proc or lambda is specified' do
      it 'executes the method name on the model and outputs the value' do
        attr = described_class.new(:blah, method: -> (model) { model.last_name })
        expect(attr.serialize(model, params)).to eq model.last_name
      end

      describe 'when serialization params are specified' do
        it 'passes the serialization params to the method' do
          params[:child] = 'Bart'
          attr = described_class.new(:blah, method: -> (model, p) { p[:child] })
          expect(attr.serialize(model, params)).to eq 'Bart'
        end
      end
    end
  end

  describe 'serialize?' do
    describe 'when :if is not specified' do
      it 'defaults to true and outputs the value' do
        attr = described_class.new(:first_name)
        expect(attr.serialize?(model, params)).to eq true
      end
    end

    describe 'when :if is specified' do
      it 'expects a proc with zero, one, or two arguments (the model and serialization params)' do
        attr = described_class.new(:first_name, if: -> { true } )
        expect(attr.serialize?(model, params)).to eq true

        attr = described_class.new(:first_name, if: -> (model) { model.first_name.present? } )
        expect(attr.serialize?(model, params)).to eq true

        params[:blah] = true
        attr = described_class.new(:first_name, if: -> (model, params) { params[:blah] } )
        expect(attr.serialize?(model, params)).to eq true
      end

      describe 'when the proc evaluates to true' do
        it 'outputs true' do
          attr = described_class.new(:first_name, if: -> { true } )
          expect(attr.serialize?(model, params)).to eq true
        end
      end

      describe 'when the proc evaluates to false' do
        it 'outputs false' do
          attr = described_class.new(:first_name, if: -> { false } )
          expect(attr.serialize?(model, params)).to eq false
        end
      end
    end
  end

  it 'works for non-ActiveRecord objects' do
    UserStruct = Struct.new(:first_name, :last_name)
    user = UserStruct.new(first_name: 'Bart', last_name: 'Simpson')
    attr = described_class.new(:first_name)
    expect(attr.serialize(user, params)).to eq 'Bart'
  end

end
