module RetrieveResource
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def retrieve_resource(object_name, options = {}, &block)
      object_name = object_name.to_s
      options.reverse_merge!({:class_name => object_name.classify, :find_method => 'find'})
      options[:param] ||= "#{options[:class_name].pluralize}Controller" == name.demodulize ? 'id' : "#{object_name}_id"
      
      method_name = "retrieve_resource_#{object_name}"
      filter_method_name = "#{method_name}_filter"
      module_eval <<-EOT, __FILE__, __LINE__
        def #{method_name}(value)
          #{options[:class_name]}.#{options[:find_method]}(value)
        end
        
        def #{filter_method_name}
          @#{object_name} ||= #{method_name}(params['#{options[:param]}'])
        end
        protected :#{method_name}, :#{filter_method_name}
      EOT

      filter_options = options.reject { |key, value| !%w(only except).include?(key.to_s) }
      prepend_before_filter filter_method_name, filter_options, &block
    end
  end
end