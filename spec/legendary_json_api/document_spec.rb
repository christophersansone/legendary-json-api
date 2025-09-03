require 'rails_helper'

RSpec.describe LegendaryJsonApi::Document do

  let(:organization) { Organization.create!(name: 'The Simpsons') }
  let(:user) { User.create!(first_name: 'Homer', last_name: 'Simpson', email: 'homer@simpsons.com', organization: organization) }
  let(:Document) { described_class }
  let(:data) { UserSerializer.serialize(user) }
  let(:included) { UserSerializer.serialize_included(user, included: [:organization], included_list: included_list) }
  let(:meta) { {} }
  let(:included_list) { LegendaryJsonApi::Serialization::IncludedList.new }
  let(:posts) { 3.times.map { Post.create!(user: user, title: 'Donuts', body: 'Mmmmm... donuts') } }

  describe '#render' do
    it 'outputs a hash' do
      expect(described_class.render(data: nil)).to be_a(Hash)
    end

    it 'outputs the data when specified' do
      document = described_class.render(data: data)
      expect(document[:data]).to eq data
    end

    it 'outputs the included when specified' do
      expect(included).to eq [OrganizationSerializer.serialize(organization)]
      document = described_class.render(data: data, included: included)
      expect(document[:data]).to eq data
      expect(document[:included]).to eq included
    end

    it 'outputs the meta when specified' do
      meta[:beer] = 'Duff'
      document = described_class.render(data: data, meta: meta)
      expect(document[:meta][:beer]).to eq 'Duff'
    end

    it 'outputs the links when specified' do
      links = { links: { self: "https://api.com/users/#{user.id}" } }
      document = described_class.render(data: data, links: links)
      expect(document[:links]).to eq links
    end
 
    describe 'errors' do
      it 'outputs the errors when specified' do
        errors = [ { status: 404 } ]
        document = described_class.render(errors: errors)
        expect(document[:errors]).to eq errors
      end

      it 'errors when both data when errors are specified, adhering to spec' do
        errors = [ { status: 404 } ]
        expect { described_class.render(data: data, errors: errors) }.to raise_error(StandardError)
      end
    end
  end


  describe '#render_model' do

    describe 'output' do
      describe ':data' do
        it 'is the serialization of the specified model' do
          output = described_class.render_model(user)
          expect(output[:data]).to eq UserSerializer.serialize(user)
        end
      end

      describe ':errors' do
        it 'is nil' do
          output = described_class.render_model(user)
          expect(output[:errors]).to eq nil
        end
      end

      describe ':meta' do
        it 'equals the original :meta value' do
          meta = { tagline: "D'oh!" }
          output = described_class.render_model(user, meta: meta)
          expect(output[:data]).to be_present
          expect(output[:meta]).to eq meta
        end
      end

      describe ':included' do
        describe 'when specified' do
          it 'includes the relationships' do
            output = described_class.render_model(user, included: [ :organization ])
            serialized_organization = OrganizationSerializer.serialize(organization)
            expect(output[:included]).to eq [ serialized_organization ]
          end
        end
        
        describe 'when not specified' do
          it 'is not present in the output' do
            output = described_class.render_model(user)
            expect(output.has_key?(:included)).to eq false
          end
        end
      end
    end

    it 'eager loads ActiveRecord models' do
      expect(LegendaryJsonApi::Serialization::EagerLoader).to receive(:eager_load!).with(user, [:organization], UserSerializer).and_call_original
      output = described_class.render_model(user, included: [ :organization ])
    end

    it 'works with non-ActiveRecord objects' do
      UserStruct = Struct.new(:id, :first_name, :last_name, :email, :organization, :job)
      user_struct = UserStruct.new(id: '123', first_name: 'Seymour', last_name: 'Skinner', email: 'seymour@skinner.com', organization: organization)
      output = described_class.render_model(user_struct, serializer: UserSerializer)
      expect(output[:data][:id]).to eq user_struct.id
      expect(output[:data]).to eq UserSerializer.serialize(user_struct)
    end
  end

  describe '#render_models' do
    before(:each) { posts }

    it 'renders the expected data' do
      output = described_class.render_models(user.posts)
      expect(output[:data].is_a?(Array)).to eq true
      expect(output[:data]).to eq posts.map { |p| PostSerializer.serialize(p) }
    end

    it 'renders the expected included' do
      comments = posts.map { |p| 3.times.map { Comment.create!(post: p, user: user, text: 'Comment') } }.flatten
      output = described_class.render_models(user.posts, included: [ :comments ])
      expect(output[:included].is_a?(Array)).to eq true
      expect(output[:included]).to eq comments.map { |c| CommentSerializer.serialize(c) }
    end

    it 'eager loads ActiveRecord models' do
      expect(LegendaryJsonApi::Serialization::EagerLoader).to receive(:eager_load!).with(user.posts, [:user], nil).and_call_original
      output = described_class.render_models(user.posts, included: [ :user ])
    end
  end

  describe '#render_exception' do

    describe 'when the exception is an ActiveRecord NotFound error' do
      it 'outputs a not found error' do
        begin
          User.find(0)
        rescue ActiveRecord::RecordNotFound => e
          output = described_class.render_exception(e)
          errors = output[:errors]
          expect(errors).to be_a Array
          expect(errors.length).to eq 1
          expect(errors.first[:status]).to eq 404
          expect(errors.first[:detail]).to be_present
        end
      end
    end

    describe 'when the exception is an ActiveRecord validation error' do
      it 'outputs a set of validation errors' do
        begin
          User.create!
        rescue ActiveRecord::RecordInvalid => e
          output = described_class.render_exception(e)
          errors = output[:errors]
          expect(errors).to be_a Array
          expect(errors.length).to eq e.record.errors.full_messages.length
          errors.each do |e|
            expect(e[:status]).to eq 422
            expect(e[:detail]).to be_present
            expect(e[:source]).to be_present
          end
        end
      end
    end
  end
end
