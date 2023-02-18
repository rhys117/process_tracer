class InstantiatedOperation
  def initialize(param)
    @passed_param = param
  end

  def run
    "instantiated #{@passed_param} operation"
  end
end