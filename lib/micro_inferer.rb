require 'pp'
require 'set'
require 'conditions_tree'
require 'rubygems'

module Micro

  class Inferer
    
    attr_accessor :max_iterations
    
    attr_reader :facts, :rules, :callbacks_suspended

    def initialize
      @rules = []
      @node_cache = {}
      @max_iterations = 10

      @facts = ::Set.new
      @added_facts = ::Set.new
      @forced_facts = ::Set.new
      @removed_facts = ::Set.new
    end

    def when(pattern)
      rule = Rule.new(self, pattern)
      @rules << rule
      rule
    end

    def when_conditions(conditions_tree)
      rule = self.when(nil)
      rule.conditions_tree = conditions_tree
      rule
    end

    def assert(*new_facts)
      new_facts = format_facts(new_facts)
      @added_facts.merge(new_facts)
      @facts.merge(new_facts)
    end
    alias_method :it_is, :assert

    # Reasserts an array of facts into the inferer causing 
    # rules to refire if they are already true
    def reassert(*forced_facts)
      forced_facts = format_facts(forced_facts)
      @forced_facts.merge(forced_facts)
      @facts.merge(forced_facts)
    end

    # Removes facts from working memory.
    def unassert(*removed_facts)
      removed_facts = format_facts(removed_facts)
      @removed_facts.merge(removed_facts)
      @facts.subtract(removed_facts)
    end
    alias_method :it_isnt, :unassert
    
    def infer
      apply_facts
      self.facts
    end
    
    def get_pattern_node(node)
      @node_cache[node.pattern] ||= node
    end

    # Stops callbacks for the actions within the passed in block. For example:
    #   @inferer.suspend_callbacks do
    #     @inferer.infer
    #   end
    def suspend_callbacks
      @callbacks_suspended = true
      yield
      @callbacks_suspended = false
    end
    
  private
    
    # Puts the facts into the right format
    def format_facts(facts)
      facts.map { |item| item.to_sym }
    end

    def apply_facts
      # prevent infinite loop
      count = 0
      # repeat until no new facts are learned
      until @added_facts.empty? && @removed_facts.empty? && @forced_facts.empty? do
        process_facts(@removed_facts) { |fact| update_facts_state(fact, false) }
        process_facts(@added_facts)   { |fact| update_facts_state(fact, true) }
        process_facts(@forced_facts) do |fact|
          # To force these to fire again, we make them false first. However we disable
          # callbacks since they aren't really false
          self.suspend_callbacks { update_facts_state(fact, false) }
          update_facts_state(fact, true)
        end
        count += 1
        raise Exception.new("Still learning new facts after #{@max_iterations} iterations") if count > (@max_iterations + 1)
      end
    end
    
    def process_facts(facts)
      return if facts.empty?
      # We clear to original array. Then any further additions have come
      # from rules firing
      tmp_facts = facts.clone
      facts.clear
          
      tmp_facts.each do |fact|
        yield fact
      end      
    end
    
    def update_facts_state(fact, state)
      @node_cache[fact.to_sym].state = state if @node_cache.has_key?(fact)
    end
    
  end

  # Caches the PatternNodes
  class Rule
    attr_accessor :conditions_tree
    attr_accessor :action_facts, :action_proc
    
    def initialize(inferer, pattern = nil)
      @inferer = inferer
      p_node = @inferer.get_pattern_node(PatternNode.new(pattern)) unless pattern.nil?
      @conditions_tree = ConditionsTree.new(nil, p_node)
    end
    
    def and(pattern)
      # get from cache
      p_node = @inferer.get_pattern_node(PatternNode.new(pattern))
      conditions_tree.and_node(p_node)
      self
    end
    
    def or(pattern)
      # get from cache
      p_node = @inferer.get_pattern_node(PatternNode.new(pattern))
      conditions_tree.or_node(p_node)
      self
    end
    
    def implies(*action_facts, &state_change_block)
      @conditions_tree.state_change_block = lambda { |state| state_changed(state) }
      @action_facts = Array(action_facts)
      @action_proc = state_change_block
      self
    end
    alias_method :it_is, :implies
    alias_method :then, :implies

    def conditions_tree=(c_tree)
      # replace PatternNodes from one in cache
      c_tree.each do |node|
        node = case node
               when PatternNode
                 # Replace with cached version
                 @inferer.get_pattern_node(node)
               when JoinNode
                 # Gotta duplicate join nodes so that we don't take across the 
                 # whole subtree
                 node.dup
               end
        @conditions_tree << node
      end
    end
    
    def fired?
      @conditions_tree.state
    end
    
    # Called when a condition tree changes its state
    def state_changed(state)
      state ? fire() : unfire()
      @action_proc.call(state) unless @action_proc.nil? || @inferer.callbacks_suspended
    end
    
    def fire
      @inferer.assert(*@action_facts)
    end

    def unfire
      @inferer.unassert(*@action_facts)
    end
    
  end

    
end



