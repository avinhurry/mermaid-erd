# frozen_string_literal: true

require "rake"

RSpec.describe "ERD tasks" do
  before do
    Rake.application = Rake::Application.new
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("test"))
    allow(Rails).to receive(:root).and_return(Pathname.new(File.expand_path("..", __dir__)))

    Rake.application.rake_require("mermaid_erd", [ File.expand_path("../lib/tasks", __dir__) ])
    Rake::Task.define_task(:environment)
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
    Rake::Task["erd:generate"].reenable
  end

  describe "erd:generate" do
    let(:generator) { instance_double(MermaidErd::Generator) }

    it "calls the MermaidErd::Generator" do
      allow(MermaidErd::Generator).to receive(:new).with(
        config_path: Rails.root.join("config/mermaid_erd.yml"),
        output_path: Rails.root.join("documentation/domain-model.md")
      ).and_return(generator)

      expect(generator).to receive(:generate)

      expect { Rake::Task["erd:generate"].invoke }.to output(/\[✔\] Mermaid ERD diagram added to:/).to_stdout
    end
  end
end
