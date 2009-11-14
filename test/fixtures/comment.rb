class Comment < ActiveRecord::Base
  belongs_to :person
  
  def to_s
    message
  end
end