module Activecube
  module Processor
    # Example of template:
    # toFloat64({{gas_price}})/1.0e9
    #
    # You can also put multiple templates in one string:
    # toFloat64({{gas_used}})*toFloat64({{gas_price}})/1.0e18
    class Template
      attr_reader :text

      TEMPLATE_REGEXP = /{{([^%]+)}}/.freeze
      TEMPLATE_METHODS_LIST = {
        empty: '{{template}}',
        any: 'any({{template}})'
      }.freeze

      def initialize(text)
        @text = text
      end

      def template_specified?
        return false unless text

        text.match?(TEMPLATE_REGEXP)
      end

      def apply_template(template_method)
        template_pattern = TEMPLATE_METHODS_LIST[template_method.to_sym]

        replaced_templates = extract_text_templates.map do |dt|
          template_pattern.gsub('{{template}}', dt)
        end

        replace_text_templates(replaced_templates)
      end

      private

      def extract_text_templates
        text.scan(TEMPLATE_REGEXP).flatten
      end

      def replace_text_templates(replaced_templates)
        text.gsub(/{{[^%]+}}/).with_index do |_, i|
          replaced_templates[i]
        end
      end
    end
  end
end
