module RetrieveResource
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def retrieve_resource(object_name, options = {}, &block)
      object_name = object_name.to_s
      options.reverse_merge!({:class_name => object_name.classify, :find_method => 'find'})
      options[:param] ||= "#{options[:class_name].pluralize}Controller" == name.demodulize ? 'id' : "#{object_name}_id"
      
      param_method_name = "retrieve_resource_by_param_#{options[:param]}"
      class_method_name = "retrieve_resource_by_class_#{options[:class_name].underscore}"
      filter_method_name = "retrieve_resource_#{object_name}_filter"
      module_eval <<-EOT, __FILE__, __LINE__
        def #{param_method_name}(value)
          #{class_method_name}(value)
        end
        
        def #{class_method_name}(value)
          #{options[:class_name].classify}.#{options[:find_method]}(value)
        end
        
        def #{filter_method_name}
          @#{object_name} ||= #{param_method_name}(params['#{options[:param]}'])
        end
        protected :#{param_method_name}, :#{class_method_name}, :#{filter_method_name}
      EOT

      filter_options = options.reject { |key, value| !%w(only except).include?(key.to_s) }
      prepend_before_filter filter_method_name, filter_options, &block
    end
  end
end