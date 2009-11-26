module RetrieveResource
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def retrieve_resource(object_name, options = {}, &block)
      object_name = object_name.to_s
      
      options.reverse_merge!({:class_name => object_name.classify, :find_method => 'find', :whiny => true})
      options[:param] ||= "#{object_name.to_s.camelcase.pluralize}Controller" == name.demodulize ? 'id' : "#{object_name}_id"
      options[:class_name] = options[:class_name].to_s
      
      find_options = options.reject { |k, v| !ActiveRecord::Base.method(:instance_eval).call('VALID_FIND_OPTIONS').include?(k) }
      
      param_method_name = "retrieve_resource_by_param_#{options[:param]}".intern
      object_method_name = "retrieve_resource_#{object_name}".intern
      
      callback_method = if options[:through]
        through_method_name = "retrieve_resource_#{object_name}_through_#{options[:through]}".intern
        
        define_method(through_method_name) do |value|
          parent_method_name = "retrieve_resource_#{options[:through]}"
          association_method_name = options[:as] || object_name.pluralize.underscore
          
          begin
            __send__(parent_method_name).__send__(association_method_name).__send__(options[:find_method], value, find_options.dup)
          rescue ActiveRecord::RecordNotFound => e
            raise e if options[:whiny]
          end
        end
        
        define_method(param_method_name) do
          __send__ through_method_name, params[options[:param]]
        end
        
        __send__ :protected, through_method_name
        
        through_method_name
      else
        class_method_name = "retrieve_resource_by_class_#{options[:class_name].underscore}".intern
        
        define_method(class_method_name) do |value|
          begin
            klass = options[:class_name].camelcase.constantize
            klass.__send__(options[:find_method], value, find_options.dup)
          rescue ActiveRecord::RecordNotFound => e
            raise e if options[:whiny]
          end
        end
        
        __send__ :protected, class_method_name
        
        class_method_name
      end
      
      define_method(param_method_name) do
        __send__ callback_method, params[options[:param]]
      end
      
      module_eval <<-EOT, __FILE__, __LINE__
        def #{object_method_name}
          @#{object_name} ||= #{param_method_name}
        end
        protected :#{param_method_name}, :#{object_method_name}
      EOT

      filter_options = options.reject { |key, value| !%w(only except).include?(key.to_s) }
      prepend_before_filter object_method_name, filter_options
    end
  end
end