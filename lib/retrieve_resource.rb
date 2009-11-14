module RetrieveResource
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def retrieve_resource(object_name, options = {}, &block)
      object_name = object_name.to_s
      options.reverse_merge!({:class_name => object_name.classify, :find_method => 'find', :whinny => true})
      options[:param] ||= "#{options[:class_name].pluralize}Controller" == name.demodulize ? 'id' : "#{object_name}_id"
      
      param_method_name = "retrieve_resource_by_param_#{options[:param]}"
      class_method_name = "retrieve_resource_by_class_#{options[:class_name].underscore}"
      object_method_name = "retrieve_resource_#{object_name}"
      
      define_method(class_method_name) do |value|
        find_options = options.reject { |o| !VALID_FIND_OPTIONS.include?(o) }
        klass = options[:class_name].classify.constantize
        method = klass.method(options[:find_method], find_options)
        begin
          method.call value
        rescue Exception => e
          raise e if options[:whinny]
        end
      end
      
      define_method(param_method_name) do
        send class_method_name, params[options[:param]]
      end
      
      module_eval <<-EOT, __FILE__, __LINE__
        def #{object_method_name}
          @#{object_name} ||= #{param_method_name}
        end
        protected :#{param_method_name}, :#{class_method_name}, :#{object_method_name}
      EOT

      filter_options = options.reject { |key, value| !%w(only except).include?(key.to_s) }
      prepend_before_filter object_method_name, filter_options, &block
    end
  end
end