# Legendary JSON:API Serializer

An ActiveRecord-aware JSON:API serializer.  Great, modern, fast, and tightly integrated with ActiveRecord.

## Why another JSON:API Serializer?

With so many JSON:API serializers for Ruby available, why another one, and why choose this one?  And with others that are not dependent on Rails, why use a library that is tightly dependent on Rails?

Tight integration with Rails is a design decision.  For Rails apps, it is a better, tighter experience, from both the developer experience and real world performance.  For non-Rails apps, look towards a different Rails-agnostic library.

Key Benefits:

* **Better Serializer Name Resolution**.  Serializer resolution occurs at the class level, for example `User` will resolve the serializers to `UserSerializer`.  Relationships can determine the class _without loading the related record_ by looking at the ActiveRecord association details.  Polymorphism works by resolving the serializer for each record.  Single Table Inheritance works without needing to define a serializer for each subclass by walking up the ancestors. And it is all done performantly: the serializer for a class is static and therefore can be cached after the initial lookup.  This all results in a super fast lookup that is consistent and rarely needs to be manually specified by overriding the `serializer` property of a relationship.
* **Better Relationship Definitions**.
* **Performance**.
  * With knowledge of ActiveRecord associations, it can know whether to fetch a record or simply read a foreign key, thereby saving a database query.
  * It maps the serializer relationships and included declarations against the associations, and automatically eager loads the needed relationships.  Automatic eager loading and enforcing strict loading makes n+1 queries a thing of the past in serializers, which is often otherwise difficult to ensure.  And it saves the developer the trouble of handwriting their
  `includes()` directive in most cases!

## Installation

In your Gemfile:

```bash
gem 'legendary_json_api'
```

## Usage

A serializer defines how a resource should be serialized, with its attributes and relationships:

```ruby
class UserSerializer < LegendaryJsonApi::Serializer
  attributes :first_name, :last_name, :email

  attribute :name do |object|
    [ object.first_name, object.last_name ].join(' ')
  end

  belongs_to :organization
  has_many :posts
  has_one :job
end
```

To serialize a single resource:

```ruby
UserSerializer.serialize(user)
```

This generates a resource object hash such as:

```ruby
{
  type: 'user',
  id: '1',
  attributes: {
    ...
  },
  relationships: {
    ...
  }
}
```

Use the Document class to generate a complete JSON:API document:

```ruby
LegendaryJsonApi::Document.render_model(user)
```

Please refer to the specs and dummy app in `spec/dummy` for usage details.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/christophersansone/legendary_json_api. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/christophersansone/legendary_json_api/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is copyright Legendary Labs LLC and available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the LegendaryJsonApi project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/christophersansone/legendary_json_api/blob/master/CODE_OF_CONDUCT.md).
