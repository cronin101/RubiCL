class Hadope::Task
  @@count = 0

  attr_reader :statements

  def initialize
    raise "Must be a subclass!" if self.class == Hadope::Task
    @@count += 1
    @statements = []
    @required_variables = []
  end

  def add_variables(*variables)
    @required_variables.push(variables).flatten!.uniq!
    self
  end
  def add_statement(statement)
    @statements.push statement
    self
  end

  def add_statements(statements)
    statements.each { |statement| add_statement statement }
    self
  end

  def name
    self.class.to_s.downcase.gsub(/\W/, '') << @@count.to_s
  end

end
