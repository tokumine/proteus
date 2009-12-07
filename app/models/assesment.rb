class Assesment < ActiveRecord::Base
  belongs_to :user
  has_many :tenements
end
