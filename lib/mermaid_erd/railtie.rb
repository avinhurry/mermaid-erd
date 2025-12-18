# frozen_string_literal: true

module MermaidErd
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path("../tasks/mermaid_erd.rake", __dir__)
    end
  end
end
