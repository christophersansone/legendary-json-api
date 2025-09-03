require 'rails_helper'

describe LegendaryJsonApi::Serialization::Relationship::HasMany do

  let(:organization) { Organization.create!(name: 'The Simpsons') }
  let(:user) { User.create!(first_name: 'Homer', last_name: 'Simpson', email: 'homer@simpsons.com', organization: organization) }
  let(:posts) { 3.times.map { Post.create!(user: user, title: 'Donuts', body: 'Mmmmm... donuts') } }
  let(:params) { {} }
  let(:expected_data_output) { { data: posts.map { |p| { type: 'post', id: p.id } } } }

  before :each do
    posts # create them
  end

  describe 'serialize' do
    describe 'when :included is true' do
      it 'outputs the data references regardless of :force_data' do
        rel = described_class.new(:posts)
        output = rel.serialize(user, included: true)
        expect(output).to eq expected_data_output

        rel = described_class.new(:posts, force_data: true)
        output = rel.serialize(user, included: true)
        expect(output).to eq expected_data_output

        rel = described_class.new(:posts, force_data: false)
        output = rel.serialize(user, included: true)
        expect(output).to eq expected_data_output
      end

      it 'also outputs a link if specified' do
        rel = described_class.new(:posts, link: 'https://api.com/posts' )
        output = rel.serialize(user, included: true)
        puts "OUTPUT: #{output}"
        expect(output[:data]).to eq expected_data_output[:data]
        expect(output[:links]).to eq({ related: 'https://api.com/posts' })
      end
    end

    describe 'when link: is specified' do
      describe 'when link is a proc' do
        it 'outputs the specified link' do
          rel = described_class.new(:posts, link: -> (user) { "https://api.com/users/#{user.id}/posts" } )
          expect(rel.serialize(user, params: params)).to eq({ links: { related: "https://api.com/users/#{user.id}/posts" } })
        end

        it 'outputs nil if the link proc returns nil' do
          rel = described_class.new(:posts, link: -> { nil } )
          expect(rel.serialize(user, params: params)).to be_nil
        end
      end

      describe 'when link is a string' do
        it 'outputs the specified link' do
          rel = described_class.new(:posts, link: "https://api.com/posts" )
          expect(rel.serialize(user, params: params)).to eq({ links: { related: "https://api.com/posts" } })
        end
      end
    end

    describe 'force_data:' do
      describe 'when specified' do
        describe 'when a proc' do
          it 'evaluates the proc and includes the data based on the truthiness of the response' do
            rel = described_class.new(:posts, force_data: -> { true } )
            expect(rel.serialize(user).has_key?(:data)).to eq true

            rel = described_class.new(:posts, force_data: -> { false } )
            expect(rel.serialize(user)).to eq nil
          end
        end

        describe 'when not a proc' do
          it 'includes the data based on the truthiness of the value' do
            rel = described_class.new(:posts, force_data: true )
            expect(rel.serialize(user).has_key?(:data)).to eq true

            rel = described_class.new(:posts, force_data: false )
            expect(rel.serialize(user)).to eq nil
          end
        end

        describe 'when true' do
          it 'outputs the array of reference objects associated with the relationship' do
            rel = described_class.new(:posts, force_data: true )
            expect(rel.serialize(user)).to eq expected_data_output
          end
        end

        describe 'when link: and force_data: are both specified' do
          it 'includes both in the output as specified' do
            rel = described_class.new(:posts, force_data: true, link: 'https://api.com/posts' )
            output = rel.serialize(user)
            expect(output.has_key?(:data)).to eq true
            expect(output.has_key?(:links)).to eq true

            rel = described_class.new(:posts, force_data: true, link: nil )
            output = rel.serialize(user)
            expect(output.has_key?(:data)).to eq true
            expect(output.has_key?(:links)).to eq false

            rel = described_class.new(:posts, force_data: false, link: 'https://api.com/posts' )
            output = rel.serialize(user)
            expect(output.has_key?(:data)).to eq false
            expect(output.has_key?(:links)).to eq true
          end
        end
      end
    end

    describe 'when :method is specified' do
      describe 'when a method name is specified' do
        it 'executes the method name on the model and outputs the value' do
          rel = described_class.new(:articles, force_data: true, method: :posts)
          expect(rel.serialize(user)).to eq(expected_data_output)
        end
      end

      describe 'when a proc or lambda is specified' do
        it 'executes the method name on the model and outputs the value' do
          rel = described_class.new(:articles, force_data: true, method: -> (user) { user.posts })
          expect(rel.serialize(user)).to eq(expected_data_output)
        end

        describe 'when the proc returns nil' do
          it 'outputs an empty array' do
            rel = described_class.new(:blah, force_data: true, method: -> { nil } )
            expect(rel.serialize(user)).to eq({ data: [] })
          end
        end
      end
    end

    describe 'when :association_name is specified' do
      it 'specifies the name of the ActiveRecord association, if different from the name' do
        rel = described_class.new(:articles, association_name: :posts, force_data: true)
        expect(rel.serialize(user)).to eq(expected_data_output)
      end
    end

    describe 'when :serializer is specified' do
      let(:custom_serializer) {
        class CustomSerializer < LegendaryJsonApi::Serializer
          type :article
          attribute :text
        end
        return CustomSerializer
      }

      let(:expected_output) { { data: posts.map { |p| { type: 'article', id: p.id } } } }

      describe 'when a serializer class is specified' do
        it 'uses the specified serializer' do
          rel = described_class.new(:posts, force_data: true, serializer: custom_serializer)
          expect(rel.serialize(user)).to eq expected_output
        end
      end

      describe 'when a proc is specified' do
        it 'uses the specified serializer by class or symbol' do
          # return a serializer
          params[:use_this_one] = custom_serializer
          rel = described_class.new(:posts, force_data: true, serializer: -> (object, params) { params[:use_this_one] })
          expect(rel.serialize(user, params: params)).to eq expected_output

          # return a symbol
          allow(LegendaryJsonApi::Serialization::Resolver).to receive(:resolve).with(:custom) { custom_serializer }
          rel = described_class.new(:posts, force_data: true, serializer: -> { :custom })
          expect(rel.serialize(user)).to eq expected_output
        end
      end
    end
  end

  describe 'serialize?' do

    it 'returns false by default, due to considerations such as performance, pagination, and permissions' do
      rel = described_class.new(:posts)
      expect(rel.serialize?(user)).to eq false
    end

    it 'returns true when :link is specified, so that the link can be output' do
      rel = described_class.new(:posts, link: 'https://api.com/posts')
      expect(rel.serialize?(user)).to eq true
    end

    it 'returns true when :force_data is true, to override the default behavior and output the data reference objects' do
      rel = described_class.new(:posts, force_data: true)
      expect(rel.serialize?(user)).to eq true
    end

    it 'returns true when :included is true, indicating that the records will be included in the document' do
      rel = described_class.new(:posts)
      expect(rel.serialize?(user, included: true)).to eq true
    end

    describe 'when :if is specified' do
      it 'returns false when :if evaluates to false, overriding any other setting' do
        rel = described_class.new(:posts, if: -> { false })
        expect(rel.serialize?(user)).to eq false

        # try every other possible override
        rel = described_class.new(:posts, if: -> { false }, link: 'https://api.com/posts', force_data: true)
        expect(rel.serialize?(user, included: true)).to eq false
      end
      
      it 'performs the other checks when :if evaluates to true (i.e. returning false is the only true override)' do
        rel = described_class.new(:posts, if: -> { true })
        expect(rel.serialize?(user)).to eq false

        rel = described_class.new(:posts, force_data: true)
        expect(rel.serialize?(user)).to eq true
      end
    end
  end

  describe 'serialize_included?' do
    it 'returns true if the record should be included, false if not' do
      rel = described_class.new(:posts)
      expect(rel.serialize_included?(user)).to eq true
    end

    describe 'when :if is specified' do
      it 'returns false when :if returns false' do
        rel = described_class.new(:posts, if: -> { false } )
        expect(rel.serialize_included?(user)).to eq false
      end

      it 'returns true when :if returns true' do
        rel = described_class.new(:posts, if: -> { true } )
        expect(rel.serialize_included?(user)).to eq true
      end
    end

    describe 'when :if is not specified' do
      it 'returns true' do
        rel = described_class.new(:posts)
        expect(rel.serialize_included?(user)).to eq true
      end
    end
  end

  describe 'serialize_included' do
    let(:included_list) { LegendaryJsonApi::Serialization::IncludedList.new }

    it 'adds the serialized result to the included list' do
      rel = described_class.new(:posts)
      result = rel.serialize_included(user, included_list: included_list)
      expect(result).to eq included_list
      included = included_list.to_a
      expect(included.length).to eq posts.length
      posts.each do |p|
        expect(included.include?(PostSerializer.serialize(p))).to eq true
      end
    end

    it 'includes the specified children' do
      posts.each { |p| 2.times.map { |i| Comment.create!(post: p, user: user, text: 'Comment') } }
      rel = described_class.new(:posts)
      result = rel.serialize_included(user, included_children: [:comments], included_list: included_list)
      expect(result).to eq included_list

      included = included_list.to_a
      expect(included.length).to eq posts.length * 3
      expect(included.select { |i| i[:type] === 'post' }.length).to eq posts.length
      expect(included.select { |i| i[:type] === 'comment' }.length).to eq posts.length * 2
    end
  end
  
end
