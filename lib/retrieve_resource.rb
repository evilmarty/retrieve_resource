module RetrieveResource
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def retrieve_resource(object_name, options = {}, &block)
      object_name = object_name.to_s
      options.reverse_merge!({:class_name => object_name.classify, :find_method => 'find'})

      param_lookup = if options[:param]
        param_lookup = "value = params['#{options[:param]}']"
      else
        <<-EOT
          defaults = ['#{object_name}_id', 'id']
          value = params[defaults.detect { |d| !params[d].nil? }]
        EOT
      end
      
      resource = "retrieve_#{object_name}"
      module_eval <<-EOT, __FILE__, __LINE__
        def #{resource}
          #{param_lookup}
          @#{object_name} ||= #{options[:class_name]}.#{options[:find_method]}(value)
        end
        protected :#{resource}
      EOT

      filter_options = options.reject { |key, value| !%w(only except).include?(key.to_s) }
      prepend_before_filter resource, filter_options, &block
    end
  end
end