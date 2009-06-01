
module AttributeChoices
  def self.included(base) #:nodoc:
    base.extend(AttributeChoicesMacro)
  end

  module AttributeChoicesMacro

    # Associate a list of display values for an attribute with a list of discreet values
    #
    # The arguments are:
    #
    # * +attribute+ - The attribute whose values you want to map to display values
    # * +choices+ - Either an +Array+ of tupples where the first value of the tupple is the attribute \
    # value and the second one is the display value mapping, or a +Hash+ where the key is the \
    # attribute value and the value is the display value mapping.
    # * +options+ - An optional hash of options:
    #   * +:localized+ - not implemented yet
    #   * +:validate+ - not implemented yet
    #
    # For example:
    #   class User < ActiveRecord::Base
    #     attribute_choices :gender,  { 'm' => "Male", 'f' => 'Female'}
    #     attribute_choices :age_group,  [
    #       ['18-24', '18 to 24 years old], 
    #       ['25-45', '25 to 45 years old']
    #     ], :localized => true, :validate => false
    #   end
    #
    # The macro adds an instance method named after the attribute, suffixed with <tt>_display</tt>
    # (e.g. <tt>gender_display</tt> for <tt>:gender</tt>) that returns the display value of the
    # attribute for a given value, or <tt>nil</tt> if a mapping for a value is missing.
    # 
    # It also adds a class method named after the attribute, suffixed with <tt>_choices</tt>
    # (e.g. <tt>User.gender_display</tt> for <tt>:gender</tt>) that returns an array of choices and values
    # in a fomrat that is suitable for passing directly to the Rails <tt>select_*</tt> helpers.
    #
    # NOTE: If you use a Hash for the choices the <tt>*_choices</tt> method returns an Array of tupples
    # which is ordered randomly
    def attribute_choices(attribute, choices, *args)
      write_inheritable_hash :attribute_choices_storage, {}
      class_inheritable_reader :attribute_choices_storage

      write_inheritable_hash :attribute_choices_options,  {}
      class_inheritable_reader :attribute_choices_options

      attribute_choices_storage[attribute.to_sym] = choices

      options = args.extract_options!
      options.reverse_merge!(:validate => false, :localized => false)
      attribute_choices_options[attribute.to_sym] = options

      if choices.is_a?(Array)
        define_method("#{attribute.to_s}_display") do
          tupple = attribute_choices_storage[attribute].detect {|i| i.first == read_attribute(attribute) }
          tupple && tupple.last
        end
      elsif choices.is_a?(Hash)
        define_method("#{attribute.to_s}_display") do
          attribute_choices_storage[attribute][read_attribute(attribute)]
        end
      end

      self.class.instance_eval do
        define_method("#{attribute.to_s}_choices") do
          attribute_choices_storage[attribute].collect(&:reverse)
        end
      end

      unless included_modules.include? InstanceMethods
        extend ClassMethods
        include InstanceMethods
      end
    end
  end
  module ClassMethods
  end
  module InstanceMethods
  end
end
