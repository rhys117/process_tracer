class SingletonOperation
  def self.run
    "singleton operation " + nested_method
  end

  def self.nested_method
    'nested method'
  end
end