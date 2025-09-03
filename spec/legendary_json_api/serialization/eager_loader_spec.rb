require 'rails_helper'

RSpec.describe LegendaryJsonApi::Serialization::EagerLoader do

  let(:eager_loader) { described_class }
  let(:organization) { Organization.create!(name: 'The Simpsons') }
  let(:user) { User.create!(first_name: 'Homer', last_name: 'Simpson', email: 'homer@simpsons.com', organization: organization) }
  let(:model) { User.find(user.id) }
  let(:posts) { 3.times.map { Post.create!(user: user, title: 'Donuts', body: 'Mmmmm... donuts') } }
  let(:comments) { posts.each { |post| 3.times.map { Comment.create!(post: post, user: model, text: 'Comment') } } }
  let(:job) { Job.create!(title: 'Nuclear Button Pusher', user: user) }

  describe '#eager_load!' do
    describe 'when an ActiveRecord model is specified' do

      describe 'belongs_to associations' do
        describe 'when not included' do
          it 'does not eager load (because serializing does not require loading the record)' do
            expect(model.association(:organization).loaded?).to eq false
            eager_loader.eager_load!(model, [])
            expect(model.association(:organization).loaded?).to eq false
            output = UserSerializer.serialize(model)
            expect(output[:relationships][:organization]).to eq({ data: { type: 'organization', id: organization.id }})
            expect(model.association(:organization).loaded?).to eq false
          end
        end

        describe 'when included' do
          it 'eager loads (because serializing the includes requires loading the record)' do
            expect(model.association(:organization).loaded?).to eq false
            eager_loader.eager_load!(model, [:organization])
            expect(model.association(:organization).loaded?).to eq true
          end
        end

        describe 'when nested included' do
          it 'eager loads (because serializing the includes requires loading the record)' do
            post = Post.find(posts.first.id)
            expect(post.association(:user).loaded?).to eq false
            eager_loader.eager_load!(post, [{ user: :organization }])
            expect(post.association(:user).loaded?).to eq true
            expect(post.user.association(:organization).loaded?).to eq true
          end
        end

        describe 'has_one associations' do
          before(:each) { job }

          describe 'when not included' do
            it 'eager loads because the record must be queried for the reference data to be output' do
              expect(model.association(:job).loaded?).to eq false
              eager_loader.eager_load!(model, [])
              expect(model.association(:job).loaded?).to eq true
              output = UserSerializer.serialize(model)
              expect(output[:relationships][:job]).to eq({ data: { type: 'job', id: job.id }})
            end
          end

          describe 'when included' do
            it 'eager loads' do
              expect(model.association(:job).loaded?).to eq false
              eager_loader.eager_load!(model, [:job])
              expect(model.association(:job).loaded?).to eq true
            end
          end

          describe 'when nested included' do
            it 'eager loads' do
              post = Post.find(posts.first.id)
              expect(post.association(:user).loaded?).to eq false
              eager_loader.eager_load!(post, [:user])
              expect(post.association(:user).loaded?).to eq true
              expect(post.user.association(:job).loaded?).to eq true
            end
          end
        end

        describe 'has_many associations' do
          describe 'when not included' do
            it 'does not eager load by default because the records are not output' do
              posts
              expect(model.association(:posts).loaded?).to eq false
              eager_loader.eager_load!(model, [])
              expect(model.association(:posts).loaded?).to eq false
              output = UserSerializer.serialize(model)
              expect(model.association(:posts).loaded?).to eq false
            end

            it 'eager loads when force_data is true' do
              class UserWithPostsSerializer < LegendaryJsonApi::Serializer
                has_many :posts, force_data: true
              end

              posts
              expect(model.association(:posts).loaded?).to eq false
              eager_loader.eager_load!(model, [], UserWithPostsSerializer)
              expect(model.association(:posts).loaded?).to eq true
              output = UserWithPostsSerializer.serialize(model)
              expect(output[:relationships][:posts][:data].length).to eq posts.length
            end
          end

          describe 'when included' do
            it 'eager loads because the records will be output in the included array' do
              posts
              expect(model.association(:posts).loaded?).to eq false
              eager_loader.eager_load!(model, [:posts])
              expect(model.association(:posts).loaded?).to eq true
            end
          end

          describe 'when nested included' do
            it 'eager loads' do
              posts
              comments
              expect(model.association(:posts).loaded?).to eq false
              eager_loader.eager_load!(model, { posts: :comments })
              expect(model.association(:posts).loaded?).to eq true
              expect(model.posts.first.association(:comments).loaded?).to eq true
            end
          end
        end
      end
    end

    describe 'when an ActiveRecord relation is specified' do
      before(:each) { posts }

      let(:relation) { Post.where(user_id: user.id) }

      it 'loads the relation' do
        expect(relation.loaded?).to_not eq true
        eager_loader.eager_load!(relation, [])
        expect(relation.loaded?).to eq true
      end

      it 'includes all included relationships' do
        expect(relation.loaded?).to_not eq true
        eager_loader.eager_load!(relation, [{ user: :organization }, :comments])
        expect(relation.loaded?).to eq true
        post = relation.to_a.first
        expect(post.association(:user).loaded?).to eq true
        expect(post.user.association(:organization).loaded?).to eq true
        expect(post.association(:comments).loaded?).to eq true
      end

      it 'does not include relationships that are not specified as included and should not otherwise be preloaded' do
        expect(relation.loaded?).to_not eq true
        eager_loader.eager_load!(relation, [:comments])
        expect(relation.loaded?).to eq true
        post = relation.to_a.first
        expect(post.association(:comments).loaded?).to eq true
        expect(post.association(:user).loaded?).to_not eq true
      end
    end
  end
end
