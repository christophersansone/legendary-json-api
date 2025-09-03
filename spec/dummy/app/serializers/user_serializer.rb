class UserSerializer < ApplicationSerializer
  attributes :first_name, :last_name, :email

  attribute :name do |object|
    [ object.first_name, object.last_name ].join(' ')
  end

  belongs_to :organization
  has_many :posts
  has_one :job
end
