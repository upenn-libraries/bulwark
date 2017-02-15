module AutomatedWorkflows
  class Agent

    attr_accessor :workflow
    attr_accessor :object_set

    def initialize(workflow, object_set)
      @workflow = workflow
      @object_set = object_set
    end

  end
end
