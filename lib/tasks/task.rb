class Hadope::Task
  @@count = 0

  attr_reader :statements

  def initialize
    @@count += 1
    raise "Must be a subclass!" if self.class == Hadope::Task

    @statements = []
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
