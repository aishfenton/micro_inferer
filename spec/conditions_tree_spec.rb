$:.unshift(File.dirname(__FILE__) + '/../lib')
require "micro_inferer"

describe 'ConditionsTree' do

  before do
  end  

  it "should have a root node that is a pattern" do
    tree = Micro::ConditionsTree.new(:wet)
    tree.root.should == Micro::PatternNode.new(:wet)
  end

  it "should join an AND node to the tree" do
    tree = Micro::ConditionsTree.new(:wet)
    tree.and(:cold)
    
    tree.root.should be_an_instance_of(Micro::AndNode)
    tree.root.left_input.should == Micro::PatternNode.new(:wet)
    tree.root.right_input.should == Micro::PatternNode.new(:cold)
  end

  it "should create the tree: wet AND (june or july)" do
    tree = Micro::ConditionsTree.new(:wet).and(:june).or(:july)
    
    tree.root.should be_an_instance_of(Micro::AndNode)
    tree.root.left_input.should == Micro::PatternNode.new(:wet)
    tree.root.right_input.should be_an_instance_of(Micro::OrNode)
    tree.root.right_input.left_input == Micro::PatternNode.new(:june)
    tree.root.right_input.right_input == Micro::PatternNode.new(:july)
  end

  it "should create the tree: (wet AND windy) or july" do
    tree = Micro::ConditionsTree.new(:july).or(:wet).and(:windy)
    
    tree.root.should be_an_instance_of(Micro::OrNode)
    tree.root.left_input.should == Micro::PatternNode.new(:july)
    tree.root.right_input.should be_an_instance_of(Micro::AndNode)
    tree.root.right_input.left_input == Micro::PatternNode.new(:wet)
    tree.root.right_input.right_input == Micro::PatternNode.new(:windy)
  end

  it "should be equal" do
    tree1 = Micro::ConditionsTree.when(:july).or(:wet).and(:windy)
    tree2 = Micro::ConditionsTree.when(:july).or(:wet).and(:windy)
    tree1.should == tree2

    tree1 = Micro::ConditionsTree.when_not(:july)
    tree2 = Micro::ConditionsTree.when_not(:july)
    tree1.should == tree2
  end

  it "should not be equal" do
    tree1 = Micro::ConditionsTree.new(:july).or(:wet).and(:windy)
    tree2 = Micro::ConditionsTree.new(:june).or(:wet).and(:windy)    
    tree1.should_not == tree2

    tree1 = Micro::ConditionsTree.when_not(:windy)
    tree2 = Micro::ConditionsTree.when(:windy)    
    tree1.should_not == tree2
  end

  it "should not be equal" do
    tree1 = Micro::ConditionsTree.new(:july).and(:wet).or(:windy)
    tree2 = Micro::ConditionsTree.new(:july).or(:wet).and(:windy)
    
    tree1.should_not == tree2
  end
  
  it "should be case equal (===)" do
    tree = Micro::ConditionsTree.new(:july).and(:wet).or(:windy)
    
    tree.root.right_input.should === Micro::OrNode.new
    tree.root.right_input.should_not == Micro::OrNode.new
    tree.root.left_input.should === Micro::PatternNode.new(:july)
  end

  it "a tree should start with a nil state" do
    tree = Micro::ConditionsTree.new(:wet).and(:windy)
    
    tree.state.should == nil
    tree.root.state.should == nil
    tree.root.left_input.state == nil
    tree.root.right_input.state == nil

    tree.root.left_input.state = true
    tree.root.state.should == nil
  end

  it "should set an AND node to true if both leaves are true" do
    tree = Micro::ConditionsTree.new(:wet).and(:windy)
    
    tree.root.left_input.state = true
    tree.root.right_input.state = true
    tree.root.state.should == true    

    tree.state.should == true    
  end

  it "should set an OR node to true if one leaf is true" do
    tree = Micro::ConditionsTree.new(:wet).or(:windy)
    
    tree.root.left_input.state = true
    tree.root.state.should == true
    tree.state.should == true    

    tree.root.right_input.state = true
    tree.root.state.should == true
    tree.state.should == true
  end

  it "should change the state back to false if leaves change from true to false" do
    tree = Micro::ConditionsTree.new(:wet).or(:windy)
    
    tree.root.right_input.state = true
    tree.root.state.should == true

    tree.root.right_input.state = false
    tree.root.state.should == false

    tree.root.left_input.state = true
    tree.root.left_input.state = false
    tree.root.state.should == false
  end

  it "should propergate its state up the tree" do
    tree = Micro::ConditionsTree.new(:wet).and(:windy).and(:freezing)
    
    tree.root.right_input.left_input.state = true
    tree.root.right_input.right_input.state = true
    tree.root.right_input.state.should == true

    tree.root.left_input.state = true
    tree.root.state.should == true
  end

  it "should not be possible to update a JoinNodes state directly" do
    tree = Micro::ConditionsTree.new(:wet).and(:windy).and(:freezing)
    lambda { tree.root.right_input.state = true }.should raise_error(NoMethodError)
  end

  it "should call the passed in block on changes of state" do
    callback = mock("callback")
    callback.should_receive(:testme).exactly(3).times
    
    tree = Micro::ConditionsTree.new(:wet).or(:windy)
    tree.state_change_block = lambda { |state| callback.testme(state) }

    # 1
    tree.root.left_input.state = true
    tree.root.right_input.state = true
    tree.root.left_input.state = false
    
    # 2
    tree.root.right_input.state = false

    # 3
    tree.root.left_input.state = true
  end
  
  it "should iterate over the tree in depth first order" do
    tree = Micro::ConditionsTree.new(:wet).and(:windy).or(:freezing).and(:snowing)
    
    nodes = []
    tree.each do |node|
      nodes << node
    end
    
    nodes[0].should == tree.root
    nodes[1].should == tree.root.left_input
    nodes[2].should == tree.root.right_input
    nodes[3].should == tree.root.right_input.left_input
    nodes[4].should == tree.root.right_input.right_input
    nodes[5].should == tree.root.right_input.right_input.left_input
    nodes[6].should == tree.root.right_input.right_input.right_input
  end

  it "should append nodes to create a tree" do
    tree = Micro::ConditionsTree.new(:wet).and(:windy).or(:freezing).and(:snowing)
    new_tree = Micro::ConditionsTree.new()
    
    tree.each do |node|
      new_tree << node.dup
    end
    
    new_tree.should == tree
  end

  it "should append nodes to create a tree when there is just a single node" do
    tree = Micro::ConditionsTree.new(:wet)
    new_tree = Micro::ConditionsTree.new()
    
    tree.each do |node|
      new_tree << node.dup
    end
    
    new_tree.should == tree
  end
  
  it "should be equal even if a symbol or a string is used for the pattern" do
    tree1 = Micro::ConditionsTree.new(:wet).and(:windy).or(:freezing)
    tree2 = Micro::ConditionsTree.new('wet').and('windy').or('freezing')
    
    tree1.should == tree2
  end  

  it "should create a tree when 'when' or 'when_not' is called" do
    tree = Micro::ConditionsTree.when(:wet).and_not(:rainy)
    tree.sub_root.should be_an_instance_of(Micro::WhenNode)
    tree.root.should be_an_instance_of(Micro::AndNotNode)
    tree.root.left_input.should == Micro::PatternNode.new(:wet)
    tree.root.right_input.should == Micro::PatternNode.new(:rainy)

    tree = Micro::ConditionsTree.when_not(:wet).or_not(:rainy)
    tree.sub_root.should be_an_instance_of(Micro::WhenNotNode)
    tree.root.should be_an_instance_of(Micro::OrNotNode)
    tree.root.left_input.should == Micro::PatternNode.new(:wet)
    tree.root.right_input.should == Micro::PatternNode.new(:rainy)
  end
  
end

describe 'Node' do

  before do
    @inferer = mock("inferer")
    @inferer.should_receive(:get_pattern_node).any_number_of_times.and_return { |node| node }
  end  

  it "should bidirectionally join/unjoin nodes" do
    and_node = Micro::JoinNode.new
    l_node = Micro::PatternNode.new(:wet)
    r_node = Micro::PatternNode.new(:windy)

    and_node.left_input = l_node
    l_node.should have_output(and_node)

    and_node.right_input = r_node
    r_node.should have_output(and_node)
    
    and_node.left_input = nil
    l_node.should_not have_output(and_node)

    and_node.right_input = nil
    r_node.should_not have_output(and_node)
  end

  it "should duplicate a JoinNode without copying inputs / outputs" do
    tree = Micro::ConditionsTree.new(:wet).and(:windy).or(:freezing)
    
    node = tree.root.right_input.dup
    node.should === tree.root.right_input
    node.left_input.should == nil
    node.right_input.should == nil    
  end

  it "should duplicate a PatternNode without copying inputs / outputs but keep the pattern" do
    tree = Micro::ConditionsTree.new(:wet).and(:windy).or(:freezing)
    
    node = tree.root.right_input.left_input.dup
    node.should == tree.root.right_input.left_input
  end

end


