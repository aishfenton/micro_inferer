require 'micro_inferer'

module Micro

  # A Directed Acyclic Tree for representing a boolean expression for a Rule. The tree consists of two
  # types of nodes: Pattern and Join. Pattern nodes represent required facts. Join nodes represent
  # a logical operation on two facts, such as AND. 
  class ConditionsTree
    attr_reader :active_branch
  
    def initialize(pattern = nil, p_node = nil)
      @sub_root = SubRootNode.new
      @active_branch = @sub_root
      @sub_root.right_input = PatternNode.new(pattern) unless pattern.nil?
      @sub_root.right_input = p_node unless p_node.nil?
    end
  
    def and(pattern)
      p_node = PatternNode.new(pattern)
      self.and_node(p_node)
    end

    def or(pattern)
      p_node = PatternNode.new(pattern)
      self.or_node(p_node)
    end

    def and_node(p_node)
      j_node = AndNode.new
      join_to_branch(j_node, p_node)
      self
    end
  
    def or_node(p_node)
      j_node = OrNode.new
      join_to_branch(j_node, p_node)
      self
    end

    # Builds the tree programatically. Nodes must be provided in the order left then right
    # top to bottom. Matches the order nodes are output from self.each
    def <<(node)
      case node
      when PatternNode
        if @active_branch.left_input.nil?
          @active_branch.left_input = node
        else
          @active_branch.right_input = node
        end
      when JoinNode
        @active_branch.right_input = node
        @active_branch = node
      else
        raise Exception.new("Didn't recognise node type: " + node.class.name)
      end     
      self
    end

    def state_change_block=(state_change_block)
      @sub_root.state_change_block = state_change_block
    end
        
    def ==(tree)
      self.root == tree.root
    end
  
    def inspect
      @sub_root.inspect
    end
  
    def state
      @sub_root.state
    end
    
    # The real root starts from the subroot's right_input. The Subroot is
    # only used to make implementation easier
    def root
      @sub_root.right_input
    end
    
    # Enumerates the tree using a Depth First Search. In practice this means an ?infix
    # order is used.
    def each
      node = root
      loop do
        yield node
        break if node.is_a? PatternNode
        yield node.left_input
        # XXX we can cheat (for now) since our expressions are only right-associtive and 
        # just walk down the right side of the tree
        node = node.right_input
      end
    end
  
  private

    def join_to_branch(j_node, p_node)
      j_node.right_input = p_node
      @active_branch.join(j_node)
      # always keep the right_most join as the active_branch
      @active_branch = j_node
    end
    
  end

  # Abstract node class. All nodes have potientally many outputs. Inputs are left to the concrete classes
  # to define. Multiple outputs allow pattern nodes (and in the future branches) to be shared between trees
  class Node
    attr_reader :state
    
    def initialize
      @state = false
      @outputs = {}
    end
    
    def add_output(node)
      @outputs[node] = node
    end
        
    def remove_output(node)
      @outputs.delete(node)
    end
  
    def has_output?(node)
      @outputs.has_key?(node)
    end
  
    def state=(state)
      return if @state == state
      
      @state = state
      # notify input nodes that state has changed
      @outputs.each_value { |node| node.child_state_changed(@state) }
    end
      
  end

  # A join node has left and right input nodes. The DAG will mostly be composed of 
  # of these with the pattern nodes are leaves. Join nodes should never be leaves
  class JoinNode < Node
    attr_accessor :left_input, :right_input

    def left_input=(new_node)
      @left_input = swap_node(@left_input, new_node)
    end

    def right_input=(new_node)
      @right_input = swap_node(@right_input, new_node)
    end

    def join(join_node)
      raise Exception.new("Only join nodes can join together") unless join_node.is_a?(JoinNode)
      join_node.left_input = self.right_input
      self.right_input = join_node
    end

    def ==(node)
      node.instance_of?(self.class) && (self.left_input == node.left_input) && (self.right_input == node.right_input)
    end

    def ===(node)
      self.class == node.class
    end

    def inspect
      "(#{left_input.inspect}, #{right_input.inspect})"
    end
    
    def dup
      self.class.new
    end

  private

    # join nodes should have their state updated internally
    def state=(state)
      super(state)
    end

    def swap_node(old_node, new_node)
      old_node.remove_output(self) unless old_node.nil?
      # register self as input to the new node
      new_node.add_output(self) unless new_node.nil?
      new_node
    end

  end

  # Created to handle the special case when a rule only has a single condition (i.e. :wet -> :raining). 
  # In this case the root node has no left_hand pattern, so always returns true for this 
  class SubRootNode < JoinNode
    attr_accessor :state_change_block

    def initialize
      super()
      # Fill left with faux node
      self.left_input = PatternNode.new("FAUX NODE -- you shouldn't see this")
    end

    def inspect
      @right_input.inspect
    end
    
    def child_state_changed(state)
      # for root node, left is always true 
      self.state = self.right_input.state
    end
      
  private
  
    def state=(state)
      return if @state == state 
      
      @state = state
      # notify call back that state has changed
      @state_change_block.call(@state) unless @state_change_block.nil?
    end
          
  end

  class AndNode < JoinNode
    def inspect
      "and#{super()}" 
    end

    def child_state_changed(state)
      # join is only true if both its children are true
      self.state = self.left_input.state && self.right_input.state
    end
  end

  class OrNode < JoinNode
    def inspect
      "or#{super()}"
    end

    def child_state_changed(state)
      # join is only true if one of its children are true
      self.state = self.left_input.state || self.right_input.state
    end
  end
  
  class PatternNode < Node    
    attr_reader :pattern
    
    def initialize(pattern)
      super()
      @pattern = pattern.to_sym
    end

    def ==(node)
      self.class == node.class && @pattern == node.pattern
    end
    
    def ===(node)
      self == node
    end

    def inspect
      @pattern.to_s
    end
        
    def dup
      self.class.new(self.pattern)
    end
    
  end
  
end