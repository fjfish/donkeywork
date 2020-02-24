namespace :donkey do
  desc "info"
  task :info do
    puts <<~EOT
      Do the donkey work:

      Creates fabricators
      Creates ember models and specs
      Creates serializers and specs
      Creates ember models
      Creates CRUD Ember views
      Creates CRUD Ember
    EOT
  end

  desc "check environment"
  task :check do
    raise "\nHold your horses! 🐴  🐎  🏇  Dev environment only! 😳\n\n" unless Rails.env.development?
  end

  desc "initialise"
  task :init do
    get_model
  end

  desc "create fabricator"
  task fabricator: [:environment, :check, :init] do
    file_name = check_file("spec/fabricators", subtype: "_fabricator")
    break unless file_name
    template_text = IO.read(File.dirname(__FILE__) + "/donkey/fabricator_template.rb.erb")
    IO.write(file_name, ERB.new(template_text).result(binding))
  end

  desc "create serializer and specs"
  task serializer_and_specs: [:environment, :check, :init] do
    serializer_file_name = check_file("app/serializers", subtype: "_serializer")
    if serializer_file_name
      template_text = IO.read(File.dirname(__FILE__) + "/donkey/fabricator_spec_template.rb.erb")
      IO.write(serializer_file_name, ERB.new(template_text).result(binding))
    end

    serializer_spec_file_name = check_file("spec/serializers", subtype: "_serializer_spec")
    if serializer_spec_file_name
      template_text = IO.read(File.dirname(__FILE__) + "/donkey/serializer_spec_template.rb.erb")
      IO.write(serializer_spec_file_name, ERB.new(template_text).result(binding))
    end

  end

  desc "create authorizer and specs"
  task authorizer_and_specs: [:environment, :check, :init] do
    authorizer_file_name = check_file("app/authorizers", subtype: "_authorizer")
    if authorizer_file_name

      update_delete_level = ask("What level should be allowed to update and delete #{model}?").to_i
      template_text = IO.read(File.dirname(__FILE__) + "/donkey/authorizer_template.rb.erb")
      IO.write(authorizer_file_name, ERB.new(template_text).result(binding))
    end

    authorizer_spec_file_name = check_file("spec/authorizors", subtype: "_authorizer_spec")
    if authorizer_spec_file_name
      def user_level_spec_generator(subject_name, level, operation_level)
        if level == 0
          update_delete_operation = operation = "not_to"
        elsif operation_level <= level
          update_delete_operation = operation = "to"
        else
          update_delete_operation = "not_to"
          operation = "to"
        end
        <<-EOT
    describe "level #{level} user" do
      before do
        allow(user).to receive(:permission_level).and_return(#{level})
      end
      it { expect(#{subject_name}).#{operation} be_creatable_by(user) }
      it { expect(#{subject_name}).#{operation} be_readable_by(user) }
      it { expect(#{subject_name}).#{update_delete_operation} be_updatable_by(user) }
      it { expect(#{subject_name}).#{update_delete_operation} be_deletable_by(user) }
    end
        EOT
      end
      template_text = IO.read(File.dirname(__FILE__) + "/donkey/authorizer_spec_template.rb.erb")
      IO.write(authorizer_spec_file_name, ERB.new(template_text).result(binding))
    end
  end

  desc "create controller"
  task controller: [:environment, :check, :init] do
    controller_file_name = check_file("app/controllers", subtype: "s_controller")
    if controller_file_name
      controller_template_text = IO.read(File.dirname(__FILE__) + "/donkey/controller_template.rb.erb")
      IO.write(controller_file_name, ERB.new(controller_template_text).result(binding))
    end
  end

  desc "create Ember model"
  task ember_model: [:environment, :check, :init] do
    ember_model_file_name = check_file("app/assets/javascripts/ember/models", subtype: "", extension: "coffee")
    if ember_model_file_name
      ember_template_text = IO.read(File.dirname(__FILE__) + "/donkey/ember_model_template.coffee.erb")
      IO.write(ember_model_file_name, ERB.new(ember_template_text).result(binding))
    end
  end

  def get_model
    @model = ask("Model name (camel pls)")
  end

  def model
    @model.constantize
  end

  def model_columns(indent_by, example: false, pre_colon: false, join_with: "\n", miss: [], transform: -> (name) { name.itself }, ember_type: false)
    indent = " " * indent_by
    indent += ":" if pre_colon
    model_column_list.map do |column|
      next if column.name.in?(miss)
      if example && column.name == "practice_id"
        "#{indent}practice { MultiTenant.current_tenant }"
      else
        value = ""
        value = " " + type_example(column) if example
        value = ember_type(column) if ember_type
        "#{indent}#{transform[column.name]}" + value
      end
    end.compact.join("#{join_with}")
  end

  def model_base_name
    @model_base_name ||= @model.snakecase
  end

  def check_file(path, subtype:, extension: "rb")
    name = "#{path}/#{model_base_name}#{subtype}.#{extension}"
    if File.exist?(name)
      continue = ask("File #{name} already exists - overwrite?")
      return false unless continue =~ %r{y}i
    end
    name
  end

  def model_column_list
    @model_column_list ||= model.columns.dup.delete_if { |x| x.name.in? %w[id sid] }.sort { |l, h| l.name <=> h.name }
  end

  def fabricate_expectations(mode)
    join_with = if mode == :model
                  ", "
                elsif mode == :test
                  "\n"
                end
    model_column_list.map do |column|
      if mode == :model
        "#{column.name}: #{type_example(column)}"
      elsif mode == :test
        "  it { expect(parsed_json.fetch(\"#{column.name}\")).to eq(#{type_example(column)}) }"
      end
    end.join(join_with)
  end

  def type_example(column)
    case column.type
    when :integer
      if column.name == "practice_id"
        "practice.id"
      else
        "1"
      end
    when :string then
      %("#{column.name.humanize}")
    when :date then
      %("2020-02-29")
    when :datetime then
      %("2020-02-29T00:00:00.000+00:00")
    else
      %("#{column.name.humanize}")
    end
  end

  def ember_type(column)
    case column.type
    when :integer, :number then
      %(: DS.attr("number"))
    when :decimal then
      %(: DS.attr("money"))
    when :date, :datetime then
      %(: DS.attr("date"))
    else
      %(: DS.attr("string"))
    end
  end
end
