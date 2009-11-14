class Person < ActiveRecord::Base
  has_many :comments
  
  def to_s
    "#{firstname} #{lastname}"
  end
end