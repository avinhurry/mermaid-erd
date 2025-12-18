# frozen_string_literal: true

require_relative "mermaid_erd/version"
require_relative "mermaid_erd/generator"
require_relative "mermaid_erd/railtie" if defined?(Rails::Railtie)

module MermaidErd
  class Error < StandardError; end
  # Your code goes here...
end
