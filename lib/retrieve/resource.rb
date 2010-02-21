module Retrieve
  class ResourceNotAvailable < Exception; end
  class InvalidAssociationType < Exception; end
  
  class Resource
    attr_reader :name, :macro, :method_name, :options, :object
    
    def initialize name, options = {}, &proc
      @name, @options, @proc = name.to_s, options, proc
      
      @macro = case
        when block_given?
          :proc
        when options.has_key?(:from)
          @method_name = options.delete :from
          :from
        when options.has_key?(:through)
          @klass = options[:class_name]
          @method_name = options[:as] || @name.pluralize.underscore
          :through
        else
          @klass = (options[:class_name] || name.camelcase).constantize
          @method_name = options[:find_method] || :find
          :class
      end
    end
    
    def retrieve controller
      return if escape_action? controller.action_name
      
      param_name = @options[:param] || (@name.pluralize == controller.controller_name ? 'id' : "#{@name}_id")
      param = controller.params[param_name]
      
      @object = case @macro
        when :proc
          retrieve_from_proc controller, param
        when :from
          method = controller.method(@method_name)
          raise NoMethodError if method.nil?
          args = returning([]) { |a| a << param if method.arity == 1 }
          method.call *args
        when :through
          @options[:through] = @options[:through].to_sym
          resource = controller.class.resources_for_retrieval[]
          retrieve_from_association resource, param
        else
          retrieve_from_class param
      end
    # rescue Exception => e
    #       raise e unless @options[:whiny] == false and e.is_a? ActiveRecord::RecordNotFound
    end
    
    def <=> resource
      if macro == :through
        if resource.macro == :through and @name == resource.options[:through]
          return 1
        else
          return -1
        end
      elsif resource.macro == :through
        return 1
      else
        return 0
      end
    end
    
  private
    def retrieve_from_proc object, param
      object.instance_exec *arguments_for_proc(param, &@proc), &@proc
    end
    
    def retrieve_from_method object, param
      method = object.method(@method_name)
      raise NoMethodError if method.nil?
      method.call *arguments_for_proc(param, &method)
    end
  
    def retrieve_from_class param
      method = @klass.method @method_name
      method.call param, find_options
    end
  
    def retrieve_from_association resource, param
      raise ResourceNotAvailable if resource.object.nil?
      raise AssociationTypeMismatch unless resource.object.class.reflections.has? @method_name
      raise InvalidAssociationType if resource.object.class.reflections[@method_name].macro == :belongs_to
      
      fetch_name = @options[:find_method] || :find
      association = resource.object.method(@method_name).call
      fetch_method = association.method fetch_name
      
      fetch_method.call param, find_options
    end
    
    def find_options
      valid_find_options = ActiveRecord::SpawnMethods::VALID_FIND_OPTIONS rescue ActiveRecord::Base::VALID_FIND_OPTIONS
      @options.reject { |k, v| !valid_find_options.include?(k) }
    end
    
    def escape_action? action_name
      action_name = action_name.to_sym
      if @options.has_key? :only
        actions = @options[:only].is_a?(Array) ? @options[:only].map(&:to_sym) : [@options[:only].to_sym]
        !actions.include? action_name
      elsif @options.has_key? :except
        actions = @options[:except].is_a?(Array) ? @options[:except].map(&:to_sym) : [@options[:except].to_sym]
        actions.include? action_name
      else
        false
      end
    end
    
    def arguments_for_proc *args, &proc
      raise ArgumentError if args.size < proc.arity
      args[0, proc.arity]
    end
  end
end