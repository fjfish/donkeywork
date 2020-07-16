namespace :donkey do
  desc "info"
  task :info do
    puts <<~EOT
      Do the donkey work:

      Creates fabricators
      Creates ember models with specs
      Creates serializers with specs
      Creates ember models
      Creates CRUD Ember views
      Creates CRUD Ember
      Creates HTML controllers
      Creates HTML views
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
    template_text = IO.read("#{template_dir}/fabricator_template.rb.erb")
    IO.write(file_name, ERB.new(template_text).result(binding))
  end

  desc "create serializer with specs"
  task serializer_with_specs: [:environment, :check, :init] do
    serializer_file_name = check_file("app/serializers", subtype: "_serializer")
    if serializer_file_name
      template_text = IO.read("#{template_dir}/serializer_template.rb.erb")
      IO.write(serializer_file_name, ERB.new(template_text).result(binding))
    end

    serializer_spec_file_name = check_file("spec/serializers", subtype: "_serializer_spec")
    if serializer_spec_file_name
      template_text = IO.read("#{template_dir}/serializer_spec_template.rb.erb")
      IO.write(serializer_spec_file_name, ERB.new(template_text).result(binding))
    end

  end

  desc "create authorizer with specs"
  task authorizer_with_specs: [:environment, :check, :init] do
    authorizer_file_name = check_file("app/authorizers", subtype: "_authorizer")
    if authorizer_file_name

      update_delete_level = ask("What level should be allowed to update and delete #{model}?").to_i
      template_text = IO.read("#{template_dir}/authorizer_template.rb.erb")
      IO.write(authorizer_file_name, ERB.new(template_text).result(binding))
    end

    authorizer_spec_file_name = check_file("spec/authorizers", subtype: "_authorizer_spec")
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
      template_text = IO.read("#{template_dir}/authorizer_spec_template.rb.erb")
      IO.write(authorizer_spec_file_name, ERB.new(template_text).result(binding))
    end
  end

  desc "create controller"
  task controller: [:environment, :check, :init] do
    controller_file_name = check_file("app/controllers", subtype: "s_controller")
    if controller_file_name
      controller_template_text = IO.read("#{template_dir}/controller_template.rb.erb")
      IO.write(controller_file_name, ERB.new(controller_template_text).result(binding))
    end
  end

  desc "create HTML controller"
  task html_controller: [:environment, :check, :init] do
    controller_file_name = check_file("app/controllers", subtype: "s_controller")
    if controller_file_name
      controller_template_text = IO.read("#{template_dir}/html_controller_template.rb.erb")
      IO.write(controller_file_name, ERB.new(controller_template_text).result(binding))
    end
  end

  desc "create HTML views"
  task html_views: [:environment, :check, :init] do
    %w[_form edit index new show].each do |base_file|
      view_file_name = check_view_file(base_file)
      if view_file_name
        view_template_text = IO.read("#{template_dir}/html_views/#{base_file}.html.erb")
        IO.write(view_file_name, ERB.new(view_template_text).result(binding))
      end
    end
  end

  desc "create Ember model"
  task ember_model: [:environment, :check, :init] do
    ember_model_file_name = check_file("app/assets/javascripts/ember/models", subtype: "", extension: "coffee")
    if ember_model_file_name
      ember_template_text = IO.read("#{template_dir}/ember_model_template.coffee.erb")
      IO.write(ember_model_file_name, ERB.new(ember_template_text).result(binding))
    end
  end

  def get_model
    @model = ask("Model name (camel pls)")
  end

  def ask(message)
    puts message
    STDIN.gets.chomp
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
    @model_base_name ||= model_with_namespace.split("/").last
  end

  def model_namespace
    @model_namespace = model_with_namespace.gsub(%r{[^/]*$}, "")
  end

  def model_with_namespace
    @model_with_namespace ||= @model.underscore
  end

  def check_file(path, subtype:, extension: "rb")
    FileUtils.mkdir_p("#{path}/#{model_namespace}") if model_namespace.length > 0
    name = "#{path}/#{model_with_namespace}#{subtype}.#{extension}"
    if File.exist?(name)
      continue = ask("File #{name} already exists - overwrite?")
      return false unless continue =~ %r{y}i
    end
    puts "Generating #{name}"
    name
  end

  def check_view_file(base_file_name)
    FileUtils.mkdir_p("app/views/#{model_base_name.pluralize}")
    name = "app/views/#{model_with_namespace.pluralize}/#{base_file_name}.erb"
    if File.exist?(name)
      continue = ask("File #{name} already exists - overwrite?")
      return false unless continue =~ %r{y}i
    end
    puts "Generating #{name}"
    name
  end

  def model_column_list(miss: [])
    @model_column_list ||= model.columns.dup.delete_if { |x| x.name.in? miss + %w[id sid] }.sort { |l, h| l.name <=> h.name }
  end

  def html_form_generator
    model_column_list(miss: %w[created_at updated_at]).map do |column|
      <<-EOT
  <div class="field mt3">
    <%= f.label :#{column.name} %><br>
    <%= #{generate_column(column)} %>
  </div>
      EOT
    end.join("\n")
  end

  def generate_column(column)
    column_name = column.name
    if column.name.ends_with?("_id")
      %<f.select :#{column_name}, [["Select if required", nil]] + #{column_name[0..-3].camelize}.all.map { |#{column_name.first(3)}| [#{column_name.first(3)}.name,#{column_name.first(3)}.id]}>
    elsif column.type == 'boolean'
      %<f.check_box :#{column_name}>
    else
      %<f.text_field :#{column_name}>
    end
  end

  def name_if_id(column_name)
    if column_name.ends_with?("_id")
      %<#{column_name}.name>
    else
      column_name
    end
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

  def gem_root
    @gem_root ||= Gem::Specification.find_by_name("donkeywork").gem_dir
  end

  def template_dir
    @template_dir ||= "#{gem_root}/templates"
  end
end
