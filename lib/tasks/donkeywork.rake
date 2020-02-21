
namespace :donkeywork do
  desc "info"
  task :info do
    puts <<~EOT
      Do the donkey work:

      Creates fabricators
      Creates ember models and specs
      Creates serialzers and specs
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
  task fabricator:  [:environment, :check, :init] do
    file_name = check_file("spec/fabricators", subtype: "_fabricator")
    break unless file_name
    template_text = IO.read(File.dirname(__FILE__) + "/donkey/fabricator_template.rb.erb")
    IO.write(file_name, ERB.new(template_text).result(binding))
  end

  desc "create serializer and specs"
  task serializer_and_specs:  [:environment, :check, :init] do
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
  task authorizer_and_specs:  [:environment, :check, :init] do
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
  task controller:  [:environment, :check, :init] do
    controller_file_name = check_file("app/controllers", subtype: "s_controller")
    if controller_file_name
      controller_template_text = IO.read(File.dirname(__FILE__) + "/donkey/controller_template.rb.erb")
      IO.write(controller_file_name, ERB.new(controller_template_text).result(binding))
    end
  end

  def get_model
    @model = ask("Model name (camel pls)")
  end

  def model
    @model.constantize
  end

  def model_columns(indent_by, example: false, pre_colon: false, trailling: "\n", miss: [])
    indent = " " * indent_by
    indent = indent + ":" if pre_colon
    model_column_list.map do |column|
      next if column.name.in?(miss)
      if example && column.name == "practice_id"
        "#{indent}practice { MultiTenant.current_tenant }"
      else
        value = ""
        value = " " + (column.type == :integer ? "0" : %Q("#{column.name.humanize}")) if example
        "#{indent}#{column.name}" + value
      end
    end.join("#{trailling}")
  end

  def model_base_name
    @model_base_name ||= @model.snakecase
  end

  def check_file(path, subtype:)
    name = "#{path}/#{model_base_name}#{subtype}.rb"
    if File.exists?("#{path}/#{model_base_name}#{subtype}.rb")
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
      example =
        case column.type
        when :integer
          if column.name == "practice_id"
            "practice.id"
          else
            "1"
          end
        when :string then '"string"'
        when :date then '"2020-02-29"'
        when :datetime then '"2020-02-29T00:00:00.000+00:00"'
        else '"XXX"'
        end
      if mode == :model
        "#{column.name}: #{example}"
      elsif mode == :test
        "  it { expect(parsed_json.fetch(\"#{column.name}\")).to eq(#{example}) }"
      end
    end.join(join_with)
  end
end
