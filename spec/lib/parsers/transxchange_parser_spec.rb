require 'spec_helper'

describe Parsers::TransxchangeParser do 
  
  def example_file filename
    File.join(RAILS_ROOT, 'spec', 'examples', 'TNDS', filename)
  end
  
  def get_routes(parser, params)
    routes = []
    parser.parse_routes(*params){ |route| routes << route }
    routes
  end
  
  describe 'when parsing an example file of route data' do 
    
    before do 
      @parser = Parsers::TransxchangeParser.new
      @file = example_file("SVRYSDO005-20120130-80845.xml")
    end
    
    it 'should extract the number from a route' do 
      routes = get_routes(@parser, [@file, nil, nil, nil, verbose=false, region_name='Yorkshire'])
      routes.first.number.should == '5'
    end
    
    it 'should set the region of a route' do 
      mock_region = mock_model(Region)
      Region.stub!(:find_by_name).with("Yorkshire").and_return(mock_region)
      routes = get_routes(@parser, [@file, nil, nil, nil, verbose=false, region_name='Yorkshire'])
      routes.first.region.should == mock_region
    end

  end
  
  describe 'when parsing an index file for a zip of route data files' do 
    
    before(:all) do 
      @parser = Parsers::TransxchangeParser.new
      @parser.parse_index(example_file('index.txt'))
    end
  
    it 'should return a hash of filenames to regions' do 
      @parser.region_hash['SVRYSDO005-20120130-80845.xml'].should == 'Yorkshire'
    end
    
  end
end