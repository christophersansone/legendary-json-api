class OrganizationSerializer < ApplicationSerializer
  attributes :name

  has_many :users
end
