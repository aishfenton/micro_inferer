$:.unshift(File.dirname(__FILE__) + '/../lib')
require "micro_inferer"

describe Micro::Inferer do

  before do
    @inferer = Micro::Inferer.new
  end

  it "should add 2 new rules" do
    @inferer.when(:wet).then(:raining)
    @inferer.when(:raining).and(:cold).it_is(:winter)
    @inferer.rules.size.should == 2
  end

  it "should declare 2 new facts" do
    @inferer.it_is(:wet)
    @inferer.assert(:cold)
    @inferer.facts.size.should == 2
    @inferer.facts.should == Set[:wet, :cold]
  end

  it "should infer a simple fact" do
    @inferer.when(:wet).it_is(:raining)
    @inferer.it_is(:wet)
    @inferer.infer.should include(:raining)
  end

  it "should infer a fact when from another rule firing" do
    @inferer.when(:wet).it_is(:raining)
    @inferer.when(:raining).and(:cold).it_is(:winter)
    @inferer.it_is(:wet)
    @inferer.it_is(:cold)
    @inferer.infer.should include(:winter)
  end

  it "shouldn't infinitly cycle if two rules imply each other" do
    @inferer.when(:a).implies(:b)
    @inferer.when(:b).implies(:a)
    @inferer.assert(:a)

    @inferer.infer
    @inferer.facts.should == Set[:a, :b]
  end

  it "should infer a fact when there is complex logic" do
    @inferer.when(:wet).it_is(:raining)
    @inferer.when(:raining).and(:cold).it_is(:winter)
    @inferer.when(:winter).and(:no_money).then(:in_doors)
    @inferer.when(:in_doors).and(:wet).and(:out_of_beer).or(:monther_in_law_over).then(:bad_times)
    @inferer.when(:in_doors).and(:have_beer).or(:good_tv).then(:good_times)

    @inferer.when(:in_doors).and(:have_beer).or(:good_tv).then(:good_times)

    @inferer.assert(:wet)
    @inferer.assert(:cold)
    @inferer.assert(:no_money)
    @inferer.assert(:have_beer)

    @inferer.infer.should == Set[:wet, :raining, :cold, :winter, :no_money, :have_beer, :in_doors, :good_times]
  end

  it "should limit the amount of cycles when infering" do
    @inferer.max_iterations = 5
    @inferer.when(:a).then(:b)
    @inferer.when(:b).then(:c)
    @inferer.when(:c).then(:d)
    @inferer.when(:d).then(:e)
    @inferer.when(:e).then(:f)
    @inferer.when(:f).then(:g)
    
    @inferer.assert(:a)
    
    lambda { @inferer.infer }.should raise_error
  end

  it "should remove facts from working memory when unasserted" do
    @inferer.when(:wet).it_is(:raining)
    @inferer.assert(:wet)
    @inferer.infer.should == Set[:wet, :raining]

    @inferer.unassert(:wet)
    @inferer.infer.should == Set[]
  end
  
  it "should call the passed in block when the rule fires" do
    callback = mock("callback")
    callback.should_receive(:changed).once
    
    @inferer.when(:raining).and(:cold).then(:winter) { |state| callback.changed }
    @inferer.assert(:raining, :cold)
    @inferer.infer
  end

  it "should call the passed in block when it changes from fired to non-fired" do
    callback = mock("callback")
    callback.should_receive(:changed).twice
    
    @inferer.when(:raining).and(:cold).then(:winter) { |state| callback.changed }
    @inferer.assert(:raining, :cold)
    @inferer.infer
    @inferer.unassert(:cold)
    @inferer.infer
  end

  it "shouldn't call the passed in block if the state hasn't changed" do
    callback = mock("callback")
    callback.should_receive(:changed).twice
    
    @inferer.when(:raining).and(:cold).then(:winter) { |state| callback.changed }
    # 1
    @inferer.assert(:raining, :cold)
    @inferer.infer
    @inferer.assert(:cold)
    @inferer.infer

    # 2
    @inferer.unassert(:cold)
    @inferer.infer    
    @inferer.unassert(:raining)
    @inferer.infer    
    @inferer.unassert(:something_else)
    @inferer.infer    
  end
  
  it "should reassert a fact causing it to fire again" do
    callback = mock("callback")
    callback.should_receive(:changed).exactly(2)

    @inferer.when(:wet).it_is(:raining) { |state| callback.changed }
    
    # 1
    @inferer.assert(:wet)
    @inferer.infer
    # 2
    @inferer.reassert(:wet)
    @inferer.infer
  end

  it "should not fire again when reasserting a fact if the parent clause hasn't changed state" do
    callback = mock("callback")
    callback.should_receive(:changed).once

    @inferer.when(:wet).or(:cold).it_is(:winter) { |state| callback.changed }
    
    # 1
    @inferer.assert(:wet, :cold)
    @inferer.infer
    @inferer.reassert(:wet)
    @inferer.infer    
  end

  it "should create a rule when a condition tree used (as opposed to individual facts)" do
    tree = Micro::ConditionsTree.new(:raining).and(:cold)
    @inferer.when_conditions(tree).then(:winter)
    
    @inferer.assert(:raining, :cold)
    @inferer.infer.should == Set[:raining, :cold, :winter]
  end

  it "should share a single PatternNode between all rules (depsite how they are created)" do
    tree = Micro::ConditionsTree.new(:raining).and(:cold)
    @inferer.when_conditions(tree)
    
    @inferer.when(:cold)
    @inferer.rules[0].conditions_tree.root.right_input.should be_eql(@inferer.rules[1].conditions_tree.root)
  end

  it "should suspend callbacks when suspend_callbacks is used" do
    callback = mock("callback")
    callback.should_not_receive(:changed)

    @inferer.when(:wet).it_is(:winter) { |state| callback.changed }
    
    @inferer.assert(:wet, :cold)
    @inferer.suspend_callbacks {  @inferer.infer }
  end

end
