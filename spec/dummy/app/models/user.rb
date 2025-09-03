class User < ApplicationRecord
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true

  belongs_to :organization
  has_many :posts
  has_one :job
end
