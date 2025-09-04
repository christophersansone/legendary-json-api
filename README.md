# Legendary JSON:API Serializer

An ActiveRecord-aware JSON:API serializer.  Great, modern, fast, and tightly integrated with ActiveRecord.

## Why another JSON:API Serializer?

With so many JSON:API serializers for Ruby available, why another one, and why choose this one?  And with others that are not dependent on Rails, why use a library that is tightly dependent on Rails?

Tight integration with Rails is a design decision.  For Rails apps, it is a better, tighter experience, both for the developer experience and real world performance.  For non-Rails apps, look towards a different Rails-agnostic library.

Key Benefits:

* Strong conventions with a familiar syntax and strong public API.
* **Better Serializer Name Resolution**.
  * Serializers are resolved by class name, so for example, the serializer for `User` will be resolved to `UserSerializer`.
  * Relationships can determine the class _without loading the related record_ by looking at the ActiveRecord association details.
  * Polymorphism inherently Just Works by resolving the serializer for each record's class.
  * Inheritance such as STI works whether there is a serializer for each subclass or a serializer for the parent.  The resolver walks up the class ancestry to find a match.
  * It is all done performantly: the default serializer for a class is static and therefore can be cached after the initial lookup.  After the initial resolution for a class, subsequent attempts are just a hash lookup.
  * Which serializer to use can always be overridden, e.g. on the relationship definition.
* **Better Relationship Definitions**.
  * When relationships align with ActiveRecord associations, the serializer needs to be told less because it can look up the information that it needs.  For example, there is no need to specify directives like `polymorphic: true` or `foreign_key: :user_id` like other libraries, because this detail is specified on the ActiveRecord association instead.
* **Performance**.
  * With knowledge of ActiveRecord associations, it can know whether to fetch a `belongs_to` record, or simply read a foreign key and therefore avoid a database query.  Just by defining `belongs_to :user` in the serializer, it has what it needs to discover the relationship type, foreign key, and optimize the proceess.
  * It **automatically eager loads the relationships necessary for serialization**.  It does so by mapping the serializer relationships of the records being serialized and all `included` records, analyzes the serializer relationships against the ActiveRecord associations, and invokes a `preload` to eager load them.  It also enforces `strict_loading` to verify they are all accounted for.  By doing so, n+1 queries by the serialization layer are no longer a concern, and it saves the developer the trouble of handwriting their
  `includes()` directive to match!  (In some cases, such as when an attribute or relationship is customized by a block, a manual `includes` may still be necessary.)
  * It uses a sensible pattern for outputting relationships:
    * When a relationship has a `link` defined:
      * When the relationship is `included`, both the `link` and `data` are output.
      * When the relationship is not `included`, only the `link` is output to minimize database queries.  This can be overridden with the `force_data: true` directive.
    * When a relationship does not have a `link` defined:
      * `belongs_to` will output the `data`, using the foreign key if available.  If the relationship is `included`, the record must be fetched anyway, so it uses the record itself instead.
      * `has_one` will output the `data` and must fetch the record in order to do so, regardless of whether it is `included` or not.
      * `has_many` relationships are not output by default due to the performance implications.  If the relationship is `included`, it will output the `data`.  If the relationship is not `included`, use the `force_data: true` directive to force the `data` to be output.  _(Recommendation: always define a `link` for `has_many` relationships.)_
* While it's super-charged with ActiveRecord, it works with other Ruby objects.

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
