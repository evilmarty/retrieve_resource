require File.dirname(__FILE__) + '/test_helper.rb'

class PeopleController < ActionController::Base
  retrieve_resource :person, :conditions => {:firstname => 'John'}
  
  def show
    render :text => @person
  end
  
  def rescue_action(e) raise e end
end

class CommentsController < ActionController::Base
  retrieve_resource :comment, :only => [:show]
  retrieve_resource :person, :whiny => false
  
  def index
    render :text => @person
  end
  
  def show
    render :text => @comment
  end
  
  def rescue_action(e) raise e end
end

class NormalControllerTest < ActionController::TestCase  
  load_schema
  load_fixtures
  
  def setup
    @controller = PeopleController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    
    ActionController::Routing::Routes.draw do |map|
      map.resources :people
    end
  end
  
  def test_person_model
    person = Person.find 1
    assert_equal 'John Doe', person.to_s
  end
  
  def test_correct_resource_retrieved
    process :show, {:id => 1}
    assert_equal 'John Doe', @response.body
  end
  
  def test_resource_not_found
    assert_raise ActiveRecord::RecordNotFound do
      process :show, {:id => 3}
    end
  end
  
  def test_retrieval_with_conditions
    assert_raise ActiveRecord::RecordNotFound do
      process :show, {:id => 2}
    end
  end
  
  def test_object_name_method
    assert_respond_to @controller, :retrieve_resource_person
  end
  
  def test_object_class_method
    assert_respond_to @controller, :retrieve_resource_by_class_person
  end
  
  def test_object_param_method
    assert_respond_to @controller, :retrieve_resource_by_param_id
  end
end

class QuiteControllerTest < ActionController::TestCase  
  load_schema
  load_fixtures
  
  def setup
    @controller = CommentsController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    
    ActionController::Routing::Routes.draw do |map|
      map.resources :comments
    end
  end
  
  def test_comment_model
    comment = Comment.find 1
    assert_equal 'Birdman is better!', comment.to_s
  end
  
  def test_correct_primary_resource_retrieved
    process :show, {:id => 1}
    assert_equal 'Birdman is better!', @response.body
  end
  
  def test_correct_secondary_resource_retrieved
    process :index, {:person_id => 1}
    assert_equal 'John Doe', @response.body
  end
  
  def test_resource_not_found
    assert_nothing_raised ActiveRecord::RecordNotFound do
      process :index, {:id => 3}
    end
  end
end