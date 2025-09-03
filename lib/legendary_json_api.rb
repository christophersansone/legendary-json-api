# frozen_string_literal: true

require_relative "legendary_json_api/version"
require_relative "legendary_json_api/config"
require_relative "legendary_json_api/document"
require_relative "legendary_json_api/serializer"
require_relative "legendary_json_api/serialization/attribute"
require_relative "legendary_json_api/serialization/eager_loader"
require_relative "legendary_json_api/serialization/included_list"
require_relative "legendary_json_api/serialization/includes_resolver"
require_relative "legendary_json_api/serialization/resolver"
require_relative "legendary_json_api/serialization/errors/error"
require_relative "legendary_json_api/serialization/errors/record_invalid"
require_relative "legendary_json_api/serialization/errors/record_not_found"
require_relative "legendary_json_api/serialization/relationship/base"
require_relative "legendary_json_api/serialization/relationship/belongs_to"
require_relative "legendary_json_api/serialization/relationship/has_many"
require_relative "legendary_json_api/serialization/relationship/has_one"

module LegendaryJsonApi
  class Error < StandardError; end
  # Your code goes here...
end
