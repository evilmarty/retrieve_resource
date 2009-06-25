module RetrieveResource
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def retrieve_resource(param, options = {}, &block)
      name = case param.to_s
        when 'id' then controller_name.singularize
        when /(.*)_id$/ then $0
        else param.to_s
      end

      options = {:find => 'find'}.merge options.symbolize_keys
      options[:object_name] ||= name
      options[:class_name] ||= name.classify
      resource = "retrieve_#{options[:object_name]}"

      module_eval <<-EOT, __FILE__, __LINE__
        protected
        def #{resource}
          @#{options[:object_name]} ||= #{options[:class_name]}.#{options[:find]}(params[:#{param}])
        end
      EOT

      filter_options = options.reject { |key, value| !%w(only except).include?(key.to_s) }
      
      prepend_before_filter resource, filter_options, &block
    end
  end
end