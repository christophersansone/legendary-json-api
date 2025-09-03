class JobSerializer < ApplicationSerializer
  attributes :title
  belongs_to :user
end
