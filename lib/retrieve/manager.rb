module Retrieve
  class Manager < Hash
    def process controller
      values.sort.each do |resource|
        ivar, object = "@#{resource.name}", resource.retrieve(controller)
        controller.instance_variable_set ivar, object
      end
    end
    
    def []= name, resource
      raise ArgumentError unless resource.is_a? Resource
      super
    end
    private :[]=
  end
end