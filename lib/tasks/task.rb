class Hadope::Task
  @@count = 0

  attr_reader :statements

  def initialize
    raise 'Must be a subclass!' if self.class == Hadope::Task
    @@count += 1
    @statements = []
    @required_variables = []
    @logger = Hadope::Logger.get
    @logger.log "Created Task: #{name.inspect}."
  end

  def add_variables(*variables)
    before = @required_variables.dup
    @required_variables.push(variables).flatten!.uniq!
    after = @required_variables
    new_variables = after - before
    @logger.log "Introduced variable(s): #{new_variables.inspect}." if new_variables.size > 0
    self
  end

  def add_statement(statement)
    @statements.push statement
    self
  end

  def add_statements(statements)
    statements.each { |statement| add_statement statement }
    @logger.log "Added statement(s): #{statements}."
    self
  end

  def name
    self.class.to_s.downcase.gsub(/\W/, '') << @@count.to_s
  end

  def variable_declarations
    @required_variables.map { |v| "#{type} #{v}" }.join(";\n  ") << ';'
  end

  def setup_statements
    "int global_id = get_global_id(0);\n  #{@input_variable} = data_array[global_id];"
  end

end
