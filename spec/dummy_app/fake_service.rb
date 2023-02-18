require_relative 'singleton_operation'
require_relative 'instantiated_operation'

class FakeService
  def self.run(param)
    first_own = first_own_method
    first_operation = SingletonOperation.run
    second_own = second_own_method
    second_operation = InstantiatedOperation.new(param).run

    "#{first_own} #{first_operation} #{second_own} #{second_operation}"
  end

  def self.first_own_method
    'first own'
  end

  def self.second_own_method
    'second own'
  end
end
