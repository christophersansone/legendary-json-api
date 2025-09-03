require 'rails_helper'

RSpec.describe LegendaryJsonApi::Serializer do

  class TestUserSerializer < LegendaryJsonApi::Serializer
    type :test_user
    attributes :first_name, :last_name
    attribute :email

    attribute(:job_title) { 'Nuclear Scientist' }
    attribute(:name) { |object| [ object.first_name, object.last_name ].join(' ') }
    attribute(:favorite_beer) { |model, p| p[:beer] }

    belongs_to :organization
    has_many :posts
  end

  let(:serializer) { TestUserSerializer }
  let(:organization) { Organization.create!(name: 'The Simpsons') }
  let(:model) { User.create!(first_name: 'Homer', last_name: 'Simpson', email: 'homer@simpsons.com', organization: organization) }
  let(:params) { {} }
  let(:output) { serializer.serialize(model, params: params) }
  let(:output_attributes) { output[:attributes] }
  let(:output_relationships) { output[:relationships] }

  describe '#serialize' do
    it 'performs the serialization with the expected data type and ID' do
      expect(output).to be_a Hash
      expect(output[:type]).to eq 'test_user'
      expect(output[:id]).to eq model.id
    end

    describe 'the output' do
    
      describe 'attributes' do
        describe 'defined by #attributes' do
          it 'outputs the values associated with the same method name on the model' do
            expect(output_attributes[:first_name]).to eq model.first_name
            expect(output_attributes[:last_name]).to eq model.last_name
          end
        end

        describe 'defined by #attribute' do
          describe 'with a name only' do
            it 'outputs the value associated with the same method name on the model' do
              expect(output_attributes[:email]).to eq model.email
            end
          end

          describe 'with a block' do
            it 'outputs the value associated with the result of the block' do
              expect(output_attributes[:job_title]).to eq 'Nuclear Scientist'
            end

            it 'includes the model as the first parameter' do
              expect(output_attributes[:name]).to eq 'Homer Simpson'
            end

            it 'includes serialization parameters as the second parameter' do
              params[:beer] = 'Duff'
              expect(output_attributes[:favorite_beer]).to eq 'Duff'
            end
          end
        end

        describe 'when an :if conditional is specified' do
          describe 'when true' do
            it 'outputs the attribute' do
              class TrueConditionalSerializer < TestUserSerializer
                attribute(:conditional_first_name, if: -> { true }) { |object| object.first_name }
              end

              output = TrueConditionalSerializer.serialize(model)
              expect(output[:attributes][:conditional_first_name]).to eq model.first_name
            end
          end

          describe 'when false' do
            it 'does not output the attribute' do
              class FalseConditionalSerializer < TestUserSerializer
                attribute(:conditional_first_name, if: -> { false }) { |object| object.first_name }
              end

              output = FalseConditionalSerializer.serialize(model)
              expect(output[:attributes].has_key?(:conditional_first_name)).to eq false
            end
          end
        end

      end

      describe 'relationships' do
        it 'outputs the expected relationships' do
          expect(output_relationships[:organization]).to eq({ data: { type: 'organization', id: organization.id } })
        end

        describe 'belongs_to' do
          it 'creates the BelongsTo relationship with all the specified parameters' do
            class BelongsToTestSerializer < LegendaryJsonApi::Serializer
              belongs_to :org,
                method: :organization,
                association_name: :organization,
                serializer: OrganizationSerializer,
                link: 'https://api.com/organization',
                force_data: true,
                if: -> { false }
            end

            relationship = BelongsToTestSerializer.relationship_definitions[:org]
            expect(relationship.is_a?(LegendaryJsonApi::Serialization::Relationship::BelongsTo))
            expect(relationship.name).to eq :org
            expect(relationship.method).to eq :organization
            expect(relationship.association_name).to eq :organization
            expect(relationship.serializer).to eq OrganizationSerializer
            expect(relationship.link).to eq 'https://api.com/organization'
            expect(relationship.force_data).to eq true
            expect(relationship.conditional_proc.call).to eq false
          end
        end

        describe 'has_one' do
          it 'creates the HasOne relationship with all the specified parameters' do
            class HasOneTestSerializer < LegendaryJsonApi::Serializer
              belongs_to :org,
                method: :organization,
                association_name: :organization,
                serializer: OrganizationSerializer,
                link: 'https://api.com/organization',
                force_data: true,
                if: -> { false }
            end

            relationship = HasOneTestSerializer.relationship_definitions[:org]
            expect(relationship.is_a?(LegendaryJsonApi::Serialization::Relationship::HasOne))
            expect(relationship.name).to eq :org
            expect(relationship.method).to eq :organization
            expect(relationship.association_name).to eq :organization
            expect(relationship.serializer).to eq OrganizationSerializer
            expect(relationship.link).to eq 'https://api.com/organization'
            expect(relationship.force_data).to eq true
            expect(relationship.conditional_proc.call).to eq false
          end
        end

        describe 'has_many' do
          it 'creates the HasMany relationship with all the specified parameters' do
            class HasOneTestSerializer < LegendaryJsonApi::Serializer
              has_many :articles,
                method: :posts,
                association_name: :posts,
                serializer: PostSerializer,
                link: 'https://api.com/posts',
                force_data: true,
                if: -> { false }
            end

            relationship = HasOneTestSerializer.relationship_definitions[:articles]
            expect(relationship.is_a?(LegendaryJsonApi::Serialization::Relationship::HasMany))
            expect(relationship.name).to eq :articles
            expect(relationship.method).to eq :posts
            expect(relationship.association_name).to eq :posts
            expect(relationship.serializer).to eq PostSerializer
            expect(relationship.link).to eq 'https://api.com/posts'
            expect(relationship.force_data).to eq true
            expect(relationship.conditional_proc.call).to eq false
          end
        end
      end
    end
  end

  describe '#serialize_included' do

    let(:included_list) { LegendaryJsonApi::Serialization::IncludedList.new }
    let(:posts) { 3.times.map { Post.create!(user: model, title: 'Donuts', body: 'Mmmmm... donuts') } }
    let(:comments) { posts.each { |post| 3.times.map { Comment.create!(post: post, user: model, text: 'Comment') } } }

    before(:each) { posts }

    it 'serializes the included relationships' do
      output = serializer.serialize_included(model, included: [ :organization, :posts ], included_list: included_list)
      expect(output.length).to eq 4
      expect(output.include?(OrganizationSerializer.serialize(organization))).to eq true
      posts.each do |post|
        expect(output.include?(PostSerializer.serialize(post))).to eq true
      end
    end

    it 'serializes nested relationships' do
      comments
      output = serializer.serialize_included(model, included: [ :organization, { posts: [:comments] } ], included_list: included_list)
      expect(output.select { |o| o[:type] == 'organization' }.length).to eq 1
      expect(output.select { |o| o[:type] == 'post' }.length).to eq 3
      expect(output.select { |o| o[:type] == 'comment' }.length).to eq 9
    end

    it 'does not serialize relationships that are not included' do
      output = serializer.serialize_included(model, included: [ :organization ], included_list: LegendaryJsonApi::Serialization::IncludedList.new)
      expect(output.length).to eq 1

      output = serializer.serialize_included(model, included: [ :posts ], included_list: LegendaryJsonApi::Serialization::IncludedList.new)
      expect(output.length).to eq 3
    end

  end
end