class PostSerializer < ApplicationSerializer
  attributes :title, :body

  belongs_to :user
  has_many :comments
end
