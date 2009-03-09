$:.unshift(File.dirname(__FILE__) + '/../lib')
require "micro_inferer"

describe 'Rule' do

  before do
    @inferer = mock("inferer")
    @inferer.should_receive(:get_pattern_node).any_number_of_times.and_return { |node| node }
    
    # XXX this line should work but doesn't because of bug in rspec 
    # Fixed in trunk rspec. TODO wait for release and change
    # @inferer.stub!(:get_node).and_return { |node| node }
  end  

  it "should create a conditions tree tied to the given result" do
    rule = Micro::Rule.new(@inferer, :july).or(:wet).and(:windy).implies(:winter)
    rule.conditions_tree.should == Micro::ConditionsTree.new(:july).or(:wet).and(:windy)
    rule.action_facts.should == [:winter]
  end

  it "should have a proc defined as its result" do
    tmp_value = 1
    rule = Micro::Rule.new(@inferer, :july).implies { |state| tmp_value }
    rule.action_facts.should == []
    rule.action_proc.call(true).should == tmp_value
  end

  it "should use cached pattern nodes when building a condition" do
    inferer2 = mock('inferer2')
    inferer2.should_receive(:get_pattern_node).exactly(3).times.and_return { |node| node }
    rule = Micro::Rule.new(inferer2, :july).or(:wet).and(:windy).implies(:winter)
  end

  it "should use cached pattern nodes when a condition tree is set" do
    inferer2 = mock('inferer2')
    inferer2.should_receive(:get_pattern_node).exactly(3).times.and_return { |node| node }

    tree = Micro::ConditionsTree.new(:july).or(:wet).and(:windy)
    rule = Micro::Rule.new(inferer2)
    rule.conditions_tree = tree
    
    rule.conditions_tree.should == tree
    rule.conditions_tree.root.left_input.should be_eql(tree.root.left_input)
    rule.conditions_tree.root.right_input.left_input.should be_eql(tree.root.right_input.left_input)
    rule.conditions_tree.root.right_input.right_input.should be_eql(tree.root.right_input.right_input)
  end

  it "should use duplicate join nodes when a condition tree is set" do
    tree = Micro::ConditionsTree.new(:july).or(:wet).and(:windy)
    rule = Micro::Rule.new(@inferer)
    rule.conditions_tree = tree
    
    rule.conditions_tree.should == tree
    rule.conditions_tree.root.should_not be_eql(tree.root)
    rule.conditions_tree.root.right_input.should_not be_eql(tree.root.right_input)
  end


end
