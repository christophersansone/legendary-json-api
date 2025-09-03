class CommentSerializer < ApplicationSerializer
  attributes :text

  belongs_to :post
  belongs_to :user
end
