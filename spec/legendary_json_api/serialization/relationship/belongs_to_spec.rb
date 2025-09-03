require 'rails_helper'

describe LegendaryJsonApi::Serialization::Relationship::BelongsTo do

  let(:resolver) { described_class }
  let(:organization) { Organization.create!(name: 'The Simpsons') }
  let(:user) { User.create!(first_name: 'Homer', last_name: 'Simpson', email: 'homer@simpsons.com', organization: organization) }
  let(:post) { Post.create!(user: user, title: 'Donuts', body: 'Mmmmm... donuts') }
  let(:params) { {} }
  let(:expected_data_result) { { data: { type: 'user', id: user.id } } }

  describe 'serialize' do
    describe 'when only the name is specified' do
      it 'outputs the reference object with the type and ID' do
        rel = described_class.new(:user)
        expect(rel.serialize(post, params: params)).to eq(expected_data_result)
      end
    end


    describe 'when a method is specified' do

      describe 'when a method name is specified' do
        it 'executes the method name on the model and outputs the value' do
          rel = described_class.new(:owner, method: :user)
          expect(rel.serialize(post, params: params)).to eq(expected_data_result)
        end
      end

      describe 'when a proc or lambda is specified' do
        it 'executes the method name on the model and outputs the value' do
          rel = described_class.new(:blah, method: -> (post) { post.user })
          expect(rel.serialize(post, params: params)).to eq(expected_data_result)
        end

        describe 'when the proc returns nil' do
          it 'outputs nil' do
            rel = described_class.new(:blah, method: -> { nil } )
            expect(rel.serialize(post, params: params)).to eq({ data: nil })
          end
        end

        describe 'when serialization params are specified' do
          it 'passes the serialization params to the method' do
            child = User.create!(first_name: 'Bart', last_name: 'Simpson', email: 'bart@simpsons.com', organization: organization)
            params[:child] = child
            rel = described_class.new(:firstborn, method: -> (post, p) { p[:child] })
            expect(rel.serialize(post, params: params)).to eq({ data: { type: 'user', id: child.id } })
          end
        end
      end
    end

    describe 'when the related record does not exist' do
      it 'outputs a nil data response' do
        post.user = nil
        rel = described_class.new(:user)
        expect(rel.serialize(post, params: params)).to eq({ data: nil })
      end
    end

    describe 'when link: is specified' do
      describe 'when link is a proc' do
        it 'outputs the specified link' do
          rel = described_class.new(:user, link: -> (post) { "https://api.com/posts/#{post.user_id}" } )
          expect(rel.serialize(post, params: params)).to eq({ links: { related: "https://api.com/posts/#{post.user_id}" } })
        end

        it 'outputs the reference object if the link proc returns nil' do
          rel = described_class.new(:user, link: -> { nil } )
          expect(rel.serialize(post, params: params)).to eq(expected_data_result)
        end
      end

      describe 'when link is a string' do
        it 'outputs the specified link' do
          rel = described_class.new(:user, link: "https://api.com/users/#{user.id}" )
          expect(rel.serialize(post, params: params)).to eq({ links: { related: "https://api.com/users/#{user.id}" } })
        end
      end
    end

    describe 'when the relationship is an ActiveRecord association' do
      it 'avoids loading the record by reading the foreign key when available' do
        post.save!
        post.reload
        expect(post.association(:user).loaded?).to eq false
        rel = described_class.new(:user)
        expect(rel.serialize(post, params: params)).to eq(expected_data_result)
        expect(post.association(:user).loaded?).to eq false
      end
    end

    describe 'association_name:' do
      it 'specifies the name of the ActiveRecord association, if different from the name' do
        rel = described_class.new(:owner, association_name: :user)
        expect(rel.serialize(post, params: params)).to eq(expected_data_result)
      end
    end

    describe 'serializer:' do
      let(:custom_serializer) {
        class CustomSerializer < LegendaryJsonApi::Serializer
          type :character
          attribute :first_name
        end
        return CustomSerializer
      }

      describe 'when a serializer class is specified' do
        it 'uses the specified serializer' do
          rel = described_class.new(:user, serializer: custom_serializer)
          expect(rel.serialize(post, params: params)).to eq({ data: { type: 'character', id: user.id }})
        end
      end

      describe 'when a proc is specified' do
        it 'uses the specified serializer by class or symbol' do
          # return a serializer
          params[:use_this_one] = custom_serializer
          rel = described_class.new(:user, serializer: -> (object, params) { params[:use_this_one] })
          expect(rel.serialize(post, params: params)).to eq({ data: { type: 'character', id: user.id }})

          # return a symbol
          expect(LegendaryJsonApi::Serialization::Resolver).to receive(:resolve).with(:custom) { custom_serializer }
          rel = described_class.new(:user, serializer: -> { :custom })
          expect(rel.serialize(post, params: params)).to eq({ data: { type: 'character', id: user.id }})
        end
      end
    end

    describe 'force_data:' do
      it 'overrides the default behavior to include the data reference object' do
        rel = described_class.new(:user, force_data: true, link: 'https://simpsons.com/homer')
        result = rel.serialize(post, params: params)
        expect(result[:links]).to eq({ related: 'https://simpsons.com/homer' })
        expect(result[:data]).to eq expected_data_result[:data]
      end

      describe 'when a proc is specified' do
        it 'includes the data based on the result' do
          rel = described_class.new(:user, force_data: -> { true }, link: 'https://simpsons.com/homer')
          result = rel.serialize(post, params: params)
          expect(result[:data]).to be_present

          rel = described_class.new(:user, force_data: -> { false }, link: 'https://simpsons.com/homer')
          result = rel.serialize(post, params: params)
          expect(result[:data]).to_not be_present
        end
      end

      describe 'when link: is specified' do
        describe 'when force_data: is true' do
          it 'includes them both' do
            rel = described_class.new(:user, force_data: true, link: 'https://simpsons.com/homer')
            result = rel.serialize(post, params: params)
            expect(result[:links]).to eq({ related: 'https://simpsons.com/homer' })
            expect(result[:data]).to eq expected_data_result[:data]
          end
        end

        describe 'when force_data: is false' do
          it 'does not include the data' do
            rel = described_class.new(:user, force_data: false, link: 'https://simpsons.com/homer')
            expect(rel.serialize(post, params: params)).to eq({ links: { related: 'https://simpsons.com/homer' } })
          end
        end

        describe 'when force_data: is not specified' do
          it 'does not include the data' do
            rel = described_class.new(:user, link: 'https://simpsons.com/homer')
            expect(rel.serialize(post, params: params)).to eq({ links: { related: 'https://simpsons.com/homer' } })
          end
        end
      end

      describe 'when link: is not specified' do
        it 'has no effect because the data reference will be output regardless' do
          rel = described_class.new(:user, force_data: true)
          expect(rel.serialize(post, params: params)).to eq(expected_data_result)

          rel = described_class.new(:user, force_data: false)
          expect(rel.serialize(post, params: params)).to eq(expected_data_result)
        end
      end
    end

    describe 'when :included is true' do
      it 'includes the data reference object so that it can be referred to in the included section' do
        rel = described_class.new(:user, link: 'https://simpsons.com/homer')
        result = rel.serialize(post, params: params, included: true)
        expect(result[:links]).to eq({ related: 'https://simpsons.com/homer' })
        expect(result[:data]).to eq expected_data_result[:data]
      end
    end
  end

  describe 'serialize?' do
    describe 'when :if is not specified' do
      it 'defaults to true' do
        rel = described_class.new(:user)
        expect(rel.serialize?(post, params: params)).to eq true
      end
    end

    describe 'when :if is specified' do
      it 'expects a proc with zero, one, or two arguments (the model and serialization params)' do
        rel = described_class.new(:user,  if: -> { true } )
        expect(rel.serialize?(post, params: params)).to eq true

        rel = described_class.new(:user, if: -> (post) { post.title.present? } )
        expect(rel.serialize?(post, params: params)).to eq true

        params[:blah] = true
        rel = described_class.new(:user, if: -> (post, params) { params[:blah] } )
        expect(rel.serialize?(post, params: params)).to eq true
      end

      describe 'when the proc evaluates to true' do
        it 'outputs the attribute' do
          rel = described_class.new(:user, if: -> { true } )
          expect(rel.serialize?(post, params: params)).to eq true
        end
      end

      describe 'when the proc evaluates to false' do
        it 'does not output the attribute' do
          rel = described_class.new(:user, if: -> { false } )
          expect(rel.serialize?(post, params: params)).to eq false
        end
      end
    end
  end

  describe 'serialize_included?' do

    it 'returns true if the record should be included, false if not' do
      rel = described_class.new(:user)
      expect(rel.serialize_included?(post)).to eq true
    end

    describe 'when :if is specified' do
      it 'returns the result of the conditional' do
        rel = described_class.new(:user, if: -> { true } )
        expect(rel.serialize_included?(post)).to eq true

        rel = described_class.new(:user, if: -> { false } )
        expect(rel.serialize_included?(post)).to eq false
      end
    end

    describe 'when :if is not specified' do
      it 'returns true' do
        rel = described_class.new(:user)
        expect(rel.serialize_included?(post)).to eq true
      end
    end
  end

  describe 'serialize_included' do
    let(:included_list) { LegendaryJsonApi::Serialization::IncludedList.new }

    it 'adds the serialized result to the included list' do
      rel = described_class.new(:user)
      result = rel.serialize_included(post, included_list: included_list)
      expect(result).to eq included_list
      expect(included_list[user]).to eq UserSerializer.serialize(user)
      expect(included_list.to_a).to eq [UserSerializer.serialize(user)]
    end

    it 'includes the specified children' do
      rel = described_class.new(:user)
      result = rel.serialize_included(post, included_children: [:organization], included_list: included_list)
      expect(result).to eq included_list
      expect(included_list[user]).to eq UserSerializer.serialize(user)

      included = included_list.to_a
      expect(included.length).to eq 2
      expect(included.include?(UserSerializer.serialize(user))).to eq true
      expect(included.include?(OrganizationSerializer.serialize(organization))).to eq true
    end
  end

  describe 'with non-ActiveRecord objects' do
    it 'works as expected' do
      UserStruct = Struct.new(:id, :first_name, :last_name)
      user_struct = UserStruct.new(id: '123', first_name: 'Bart', last_name: 'Simpson')

      PostStruct = Struct.new(:id, :text, :user)
      post_struct = PostStruct.new(id: '456', text: 'Cowabunga', user: user_struct)

      rel = described_class.new(:user, serializer: :user)
      expect(rel.serialize(post_struct)).to eq({ data: { type: 'user', id: '123' }})
    end
  end
  
end