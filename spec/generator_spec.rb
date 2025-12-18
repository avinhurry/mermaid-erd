# frozen_string_literal: true

RSpec.describe MermaidErd::Generator do
  subject(:generator) { described_class.new(config_path:, output_path:) }

  let(:config_path) { Rails.root.join("tmp/test_erd.yml") }
  let(:output_path) { Rails.root.join("tmp/test_domain_model.md") }

  before do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
    File.write(config_path, { "exclude" => [] }.to_yaml)
  end

  after do
    FileUtils.rm_f(config_path)
    FileUtils.rm_f(output_path)
  end

  describe "#generate" do
    context "with a basic model" do
      before do
        ActiveRecord::Base.connection.create_table(:users, force: true) do |t|
          t.string :name
          t.string :emails
        end
        define_test_model(model_name: "TestModel", table_name: "users")
      end

      after do
        ActiveRecord::Base.connection.drop_table(:users, if_exists: true)
      end

      it "writes a valid Mermaid ERD to the output file" do
        generator.generate

        contents = File.read(output_path)

        expect(contents).to include("```mermaid")
        expect(contents).to include("erDiagram")
        expect(contents).to include("TestModel {")
        # Checks that at least one string column is called 'name' or 'emails'
        expect(contents).to match(/string\s+(name|emails)/)
      end
    end

    context "when the model is excluded in the pattern" do
      before do
        ActiveRecord::Base.connection.create_table(:users, force: true) do |t|
          t.string :name
          t.string :emails
        end
        File.write(config_path, { "exclude" => %w[TestModel] }.to_yaml)
        define_test_model(model_name: "TestModel", table_name: "users")
      end

      after do
        ActiveRecord::Base.connection.drop_table(:users, if_exists: true)
      end

      it "omits excluded models from the ERD" do
        generator.generate

        expect(File.read(output_path)).not_to include("TestModel")
      end
    end

    context "when only specific models are requested" do
      before do
        File.write(config_path, { "exclude" => [], "only" => [ "TestModel" ] }.to_yaml)
        ActiveRecord::Base.connection.create_table(:users, force: true) { |t| t.string(:name) }
        ActiveRecord::Base.connection.create_table(:others, force: true) { |t| t.string(:name) }

        define_test_model(model_name: "TestModel", table_name: "users")
        define_test_model(model_name: "OtherModel", table_name: "others")
      end

      after do
        ActiveRecord::Base.connection.drop_table(:users, if_exists: true)
        ActiveRecord::Base.connection.drop_table(:others, if_exists: true)
      end

      it "includes only the listed models" do
        generator.generate

        contents = File.read(output_path)
        expect(contents).to include("TestModel {")
        expect(contents).not_to include("OtherModel")
      end
    end


    context "when multiple only and exclude patterns are provided" do
      before do
        File.write(config_path, { "exclude" => [ "ExcludedModel", "Baz*" ], "only" => [ "FooModel", "BarModel", "BazModel" ] }.to_yaml)

        ActiveRecord::Base.connection.create_table(:foo_models, force: true) { |t| t.string(:name) }
        ActiveRecord::Base.connection.create_table(:bar_models, force: true) { |t| t.string(:name) }
        ActiveRecord::Base.connection.create_table(:baz_models, force: true) { |t| t.string(:name) }
        ActiveRecord::Base.connection.create_table(:other_models, force: true) { |t| t.string(:name) }

        define_test_model(model_name: "FooModel", table_name: "foo_models")
        define_test_model(model_name: "BarModel", table_name: "bar_models")
        define_test_model(model_name: "BazModel", table_name: "baz_models")
        define_test_model(model_name: "OtherModel", table_name: "other_models")
      end

      after do
        %i[foo_models bar_models baz_models other_models].each do |table|
          ActiveRecord::Base.connection.drop_table(table, if_exists: true)
        end
      end

      it "includes only whitelisted models and still respects exclusions" do
        generator.generate

        contents = File.read(output_path)
        expect(contents).to include("FooModel {")
        expect(contents).to include("BarModel {")

        expect(contents).not_to include("BazModel")
        expect(contents).not_to include("OtherModel")
      end

      it "does not render associations to models outside the inclusion list" do
        stub_const("FooModel", Class.new(ApplicationRecord) do
          self.table_name = "foo_models"
          belongs_to :other_model, class_name: "OtherModel"
        end)

        generator.generate

        contents = File.read(output_path)
        expect(contents).not_to include("FooModel }o--|| OtherModel")
      end
    end


    context "when the model has a polymorphic belongs_to" do
      before do
        ActiveRecord::Base.connection.create_table(:polymorphic_models, force: true) do |t|
          t.string :record_type
          t.bigint :record_id
        end

        stub_const("PolymorphicModel", Class.new(ApplicationRecord) do
          self.table_name = "polymorphic_models"
          belongs_to :record, polymorphic: true
        end)
      end

      after do
        ActiveRecord::Base.connection.drop_table(:polymorphic_models, if_exists: true)
      end

      it "skips polymorphic associations to avoid blank targets" do
        generator.generate

        contents = File.read(output_path)
        expect(contents).to include("PolymorphicModel {")
        expect(contents).not_to include("PolymorphicModel }o--||")
      end
    end

    context "when the model has a belongs_to without a class name" do
      before do
        ActiveRecord::Base.connection.create_table(:no_class_models, force: true) do |t|
          t.bigint :foo_id
        end

        stub_const("NoClassModel", Class.new(ApplicationRecord) do
          self.table_name = "no_class_models"
          belongs_to :foo, class_name: "NonexistentModel"
        end)

        reflection = NoClassModel.reflect_on_all_associations(:belongs_to).first
        allow(reflection).to receive(:class_name).and_return("")
        allow(NoClassModel).to receive(:reflect_on_all_associations).with(:belongs_to).and_return([ reflection ])
      end

      after do
        ActiveRecord::Base.connection.drop_table(:no_class_models, if_exists: true)
      end

      it "skips associations without a target class" do
        generator.generate

        contents = File.read(output_path)
        expect(contents).to include("NoClassModel {")
        expect(contents).not_to include("NoClassModel }o--||")
      end
    end

    context "when the config file is missing" do
      it "falls back to an empty exclusion list" do
        FileUtils.rm_f(config_path)

        expect { generator.generate }.not_to raise_error
        expect(File.exist?(output_path)).to be(true)
      end
    end

    context "when the config file has invalid YAML" do
      before { File.write(config_path, "invalid: [this is : bad") }

      it "raises a YAML syntax error" do
        expect do
          generator.generate
        end.to raise_error(/YAML syntax error/)
      end
    end

    context "when the environment is production" do
      before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production")) }

      it "raises an error" do
        expect do
          generator.generate
        end.to raise_error(/only allowed in development/)
      end
    end

    context "when the model has an integer array column" do
      before do
        ActiveRecord::Base.connection.create_table(:test_array_models, force: true) do |t|
          t.integer "contract_period_years", default: [], null: false, array: true
        end

        define_test_model(model_name: "TestArrayModel", table_name: "test_array_models")
      end

      after do
        ActiveRecord::Base.connection.drop_table(:test_array_models, if_exists: true)
      end

      it "renders the array column as array[integer]" do
        generator.generate

        expect(File.read(output_path)).to include("array[integer] contract_period_years")
      end

      it "does not render nested array brackets" do
        generator.generate
        expect(File.read(output_path)).not_to include("array[integer[]]")
      end
    end

    context "when the model has a varchar array column" do
      before do
        ActiveRecord::Base.connection.create_table(:test_varchar_array_models, force: true) do |t|
          t.string :tags, array: true, default: [], null: false
        end
        define_test_model(model_name: "TestVarcharArrayModel", table_name: "test_varchar_array_models")
      end

      after { ActiveRecord::Base.connection.drop_table(:test_varchar_array_models, if_exists: true) }

      it "renders a varchar array as array[string]" do
        generator.generate
        expect(File.read(output_path)).to include("array[string] tags")
      end
    end

    context "when the model has a enum array column" do
      before do
        ActiveRecord::Base.connection.create_enum("pizza_toppings", %w[ham pineapple anchovy mushrooms])
        ActiveRecord::Base.connection.create_table(:test_enum_array_models, force: true) do |t|
          t.enum "ordered_toppings",
                 default: %w[ham pineapple anchovy mushrooms],
                 array: true,
                 enum_type: "pizza_toppings"
        end
        define_test_model(model_name: "TestEnumArrayModel", table_name: "test_enum_array_models")
      end

      after do
        ActiveRecord::Base.connection.drop_table(:test_enum_array_models, if_exists: true)
        ActiveRecord::Base.connection.execute("DROP TYPE IF EXISTS pizza_toppings")
      end

      it "renders an enum array as array[enum]" do
        generator.generate
        expect(File.read(output_path)).to include("array[enum] ordered_toppings")
      end
    end
  end

  def define_test_model(model_name:, table_name:)
    stub_const(model_name, Class.new(ApplicationRecord) do
      self.table_name = table_name
    end)
  end
end
