# frozen_string_literal: true

# Generates a Mermaid ERD to documentation/domain-model.md
# Excludes models listed in config/mermaid_erd.yml under `exclude`

module MermaidErd
  class Generator
    def initialize(config_path:, output_path:)
      @config_path = config_path
      @output_path = output_path
      @exclusions = begin
        if File.exist?(config_path)
          YAML.safe_load_file(config_path, aliases: true) || {}
        else
          {}
        end.fetch("exclude", [])
      rescue Psych::SyntaxError => e
        raise "YAML syntax error in #{config_path}: #{e.message}"
      end
    end

    def generate
      raise "[⚠] Mermaid ERD generation is only allowed in development environment" unless Rails.env.development?

      Rails.application.eager_load!
      models = load_models
      lines = [ "```mermaid", "erDiagram" ]

      models.each do |model|
        next unless model.table_exists?

        sanitized_name = sanitize(model.name)
        lines << "  #{sanitized_name} {"
        model.columns.each do |column|
          base_type = column.type.to_s
          type = column.array ? "array[#{base_type}]" : base_type
          lines << "    #{type} #{column.name}"
        end

        lines << "  }"

        model.reflect_on_all_associations(:belongs_to).each do |assoc|
          next if assoc.polymorphic?

          klass_name = assoc.class_name.to_s.strip
          next if klass_name.empty?

          to = sanitize(klass_name)
          next if excluded?(klass_name)

          lines << "  #{sanitized_name} }o--|| #{to} : belongs_to"
        end
      end

      lines << "```"
      FileUtils.mkdir_p(@output_path.dirname)
      File.write(@output_path, lines.join("\n"))
    end

    private

    def sanitize(name)
      name.gsub("::", "_")
    end

    def excluded?(model_name)
      @exclusions.any? { |pattern| File.fnmatch(pattern, model_name) }
    end

    def load_models
      ActiveRecord::Base.descendants.reject do |model|
        model.abstract_class? || excluded?(model.name) || model.name.start_with?("HABTM_")
      end
    end
  end
end
