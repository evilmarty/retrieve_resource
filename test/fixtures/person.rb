class Person < ActiveRecord::Base
  has_many :comments
  
  has_and_belongs_to_many :friends, :class_name => 'Person', :association_foreign_key => :friend_id, :foreign_key => :person_id, :join_table => :people_friends
  
  def to_s
    "#{firstname} #{lastname}"
  end
end