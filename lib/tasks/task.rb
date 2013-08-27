class Hadope::Task

  attr_reader :statements

  def initialize
    raise "Must be a subclass!" if self.class == Hadope::Task

    @statements = []
  end

  def add_statement(statement)
    @statements.push statement
  end

  def add_statments(statements)
    statements.each { |statement| add_statement statement }
  end

end
