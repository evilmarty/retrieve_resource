require 'retrieve/manager'
require 'retrieve/resource'

module Retrieve
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def retrieve_resource object_name, options = {}, &block
      object_name = object_name.to_s
      
      unless respond_to? :resources_for_retrieval
        @@resources_for_retrieval = Retrieve::Manager.new
        
        class << self
          def resources_for_retrieval
            @@resources_for_retrieval
          end
        end
        
        before_filter do |controller|
          controller.class.resources_for_retrieval.process controller
        end
      end
      
      @@resources_for_retrieval.send :[]=, object_name.to_sym, Retrieve::Resource.new(object_name, options, &block)
    end
  end
end