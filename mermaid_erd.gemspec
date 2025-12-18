# frozen_string_literal: true

require_relative "lib/mermaid_erd/version"

Gem::Specification.new do |spec|
  spec.name = "mermaid_erd"
  spec.version = MermaidErd::VERSION
  spec.authors = [ "Avin Hurry" ]
  spec.email = []

  spec.summary = "Generate Mermaid ER diagrams for Rails models in Markdown"
  spec.description = "Generate Mermaid ER diagrams from Rails models as Markdown-friendly output"
  spec.homepage = "https://github.com/avinhurry/mermaid_erd"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.each_line("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.require_paths = [ "lib" ]

  # Runtime dependencies
  spec.add_dependency "rails", "~> 8.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
