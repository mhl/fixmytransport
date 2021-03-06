require 'spec_helper'

describe CampaignsController do

  it 'should route /campaigns' do
    route_for(:controller => "campaigns", :action => "index").should == "/campaigns"
    params_from(:get, "/campaigns").should == { :controller => "campaigns", :action => "index" }
  end

  describe 'GET #index' do

    it 'should redirect to the issues index' do
      get :index
      response.should redirect_to("/issues")
    end

  end

  describe 'GET #add_details' do

    before do
      @default_params = {:id => 55}
      @mock_user = mock_model(User, :name => 'Test User')
      @campaign = mock_model(Campaign, :editable? => true,
                                       :initiator => @mock_user,
                                       :title= => nil,
                                       :description= => nil,
                                       :visible? => true,
                                       :friendly_id_status => mock('friendly', :best? => true))
      Campaign.stub!(:find).and_return(@campaign)
      @controller.stub!(:current_user).and_return(@mock_user)
    end

    def make_request(params=@default_params)
      get :add_details, params
    end

    it_should_behave_like "an action requiring a visible campaign"

    describe 'if the campaign is visible' do

      before do
        @campaign.stub!(:visible?).and_return(true)
      end

      it 'should set the campaign title and description to nil' do
        @campaign.should_receive(:title=).with(nil)
        @campaign.should_receive(:description=).with(nil)
        make_request()
      end

      it 'should render the template "add_details"' do
        make_request()
        response.should render_template("add_details")
      end

    end

  end

  describe 'POST #add_details' do

    before do
      @mock_user = mock_model(User, :name => "Test User")
      @default_params = {:id => 55, :campaign => {:title => 'title', :description => 'description'}}
      @campaign = mock_model(Campaign, :editable? => true,
                                       :visible? => true,
                                       :update_attributes => true,
                                       :initiator => @mock_user,
                                       :confirm => true,
                                       :save! => true,
                                       :status => :confirmed,
                                       :friendly_id_status => mock('friendly', :best? => true))
      Campaign.stub!(:find).and_return(@campaign)
      @controller.stub!(:current_user).and_return(@mock_user)
    end

    def make_request(params=@default_params)
      post :add_details, params
    end

    it_should_behave_like "an action requiring a visible campaign"

    it 'should try to update the campaign attributes' do
      @campaign.should_receive(:update_attributes).with({'title' => 'title', 'description' => 'description'})
      make_request
    end

    describe 'if the attributes can be updated' do

      before do
        @campaign.stub!(:update_attributes).and_return(true)
      end

      it 'should redirect to the campaign url' do
        make_request
        response.should redirect_to campaign_url(@campaign)
      end

    end

    describe 'if the attributes cannot be updated' do

      before do
        @campaign.stub!(:update_attributes).and_return(false)
      end

      it 'should render the template "add_details"' do
        make_request
        response.should render_template("add_details")
      end

    end

  end

  describe 'GET #show' do

    before do
      mock_assignment = mock_model(Assignment, :task_type_name => 'A test task')
      @campaign = mock_model(Campaign, :id => 8,
                                       :title => 'A test campaign',
                                       :initiator_id => 44,
                                       :editable? => true,
                                       :visible? => true,
                                       :campaign_photos => mock('campaign photos', :build => true),
                                       :location => mock_model(Stop, :points => [mock("point", :lat => 51, :lon => 0)]),
                                       :friendly_id_status => mock('friendly', :best? => true))
      Campaign.stub!(:find).and_return(@campaign)
      @default_params = { :id => 8 }
    end

    def make_request(params=@default_params)
      get :show, params
    end

    it 'should ask for the campaign by id' do
      Campaign.should_receive(:find).with('8').and_return(@campaign)
      make_request
    end

    it 'should display a campaign that has been successful' do
      @campaign.stub!(:visible?).and_return(true)
      make_request
      response.status.should == '200 OK'
    end

    it "should update a campaign that hasn't been seen by its initiator to record that it now has" do
      mock_user = mock_model(User, :is_admin? => false)
      @controller.stub!(:current_user).and_return(mock_user)
      mock_user.should_receive(:mark_seen).with(@campaign)
      make_request
    end

    it_should_behave_like "an action requiring a visible campaign"

  end

  describe 'PUT #update' do

    before do
      @expert_user = mock_model(User, :is_expert? => true)
      @campaign_user = mock_model(User, :name => "Campaign User",
                                        :save => true,
                                        :is_expert? => false)
      @mock_problem = mock_model(Problem, :token => 'problem-token')
      @mock_campaign = mock_model(Campaign, :problem => @mock_problem,
                                            :initiator => @campaign_user,
                                            :attributes= => true,
                                            :editable? => true,
                                            :visible? => true,
                                            :status => :confirmed,
                                            :save => true,
                                            :friendly_id_status => mock('friendly', :best? => true))
      Campaign.stub!(:find).and_return(@mock_campaign)
      @controller.stub!(:current_user).and_return(@campaign_user)
      @expected_wrong_user_message = "edit this problem page"
      @expected_new_access_message = :campaigns_edit_access_message
      @expected_access_message = :campaigns_update_access_message
      @default_params = { :id => 33, :campaign => { :description => 'Some stuff' }}
    end

    def make_request(params=@default_params)
      put :update, params
    end

    def do_default_behaviour
      redirect_to(campaign_url(@mock_campaign))
    end

    it_should_behave_like "an action that requires the campaign initiator"

    it 'should update the campaign with the campaign params passed' do
      @mock_campaign.should_receive(:attributes=).with("description" => 'Some stuff')
      make_request()
    end

    describe 'when the current user is an expert' do

      it 'should do the default behaviour of the action' do
        controller.stub!(:current_user).and_return(@expert_user)
        make_request @default_params
        response.should do_default_behaviour
      end

    end

    describe 'if the campaign can be saved' do

      before do
        @mock_campaign.stub!(:save).and_return(true)
      end

      it 'should redirect to the campaign url' do
        make_request()
        response.should redirect_to(campaign_url(@mock_campaign))
      end

    end

    describe 'if the campaign cannot be saved' do

      before do
        @mock_campaign.stub!(:save).and_return(false)
      end

      it 'should render the "edit" template' do
        make_request()
        response.should render_template("campaigns/edit")
      end

    end

  end

  describe 'GET #edit' do

    before do
      @expert_user = mock_model(User, :is_expert? => true)
      @campaign_user = mock_model(User, :name => "Campaign User", :is_expert? => false)
      @mock_problem = mock_model(Problem, :token => 'problem-token')
      @mock_campaign = mock_model(Campaign, :problem => @mock_problem,
                                            :initiator => @campaign_user,
                                            :title => 'A test campaign',
                                            :editable? => true,
                                            :visible? => true,
                                            :status => :confirmed,
                                            :description => 'Campaign description',
                                            :friendly_id_status => mock('friendly', :best? => true))
      Campaign.stub!(:find).and_return(@mock_campaign)
      @expected_wrong_user_message = "edit this problem page"
      @expected_new_access_message = :campaigns_edit_access_message
      @expected_access_message = :campaigns_edit_access_message
      @controller.stub!(:current_user).and_return(@campaign_user)
      @default_params = { :id => 33, :token => nil }
    end

    def make_request(params=@default_params)
      get :edit, params
    end

    def do_default_behaviour
      render_template("campaigns/edit")
    end

    it_should_behave_like "an action that requires the campaign initiator"

    describe 'when the current user is an expert' do

      it 'should do the default behaviour of the action' do
        controller.stub!(:current_user).and_return(@expert_user)
        make_request @default_params
        response.should do_default_behaviour
      end

    end

  end

  describe 'GET #join' do

    before do
      @campaign = mock_model(Campaign, :visible? => true,
                                       :editable? => true,
                                       :friendly_id_status => mock('friendly', :best? => true))
      Campaign.stub!(:find).and_return(@campaign)
    end

    def make_request
      get :join, { :id => 44 }
    end

    it "should redirect to the campaign page" do
      make_request
      response.should redirect_to(campaign_url(@campaign))
    end

  end

  describe 'GET #add_update' do

    before do
      @campaign_user = mock_model(User, :name => "Campaign User")
      @campaign_update = mock_model(CampaignUpdate)
      @mock_campaign = mock_model(Campaign, :visible? => true,
                                            :editable? => true,
                                            :initiator => @campaign_user,
                                            :status => :confirmed,
                                            :campaign_updates => mock('updates', :build => @campaign_update),
                                            :friendly_id_status => mock('friendly', :best? => true))
      Campaign.stub!(:find).and_return(@mock_campaign)
      @controller.stub!(:current_user).and_return(@campaign_user)
      @expected_wrong_user_message = "ask for advice on this problem"
      @expected_access_message = :campaigns_add_update_access_message
      @default_params = { :id => 55, :update_id => '33' }
    end

    def make_request params
      get :add_update, params
    end

    it 'should assign a campaign update to the view' do
      make_request({:id => 55})
      assigns[:campaign_update].should_not be_nil
    end

    it_should_behave_like "an action that requires the campaign initiator"
  end

  describe 'GET #add_comment' do

    before do
      @mock_campaign = mock_model(Campaign, :visible? => true,
                                            :editable? => true,
                                            :friendly_id_status => mock('friendly', :best? => true))
      Campaign.stub!(:find).and_return(@mock_campaign)
      @mock_user = mock_model(User)
      @controller.stub!(:current_user).and_return(@mock_user)
    end

    def make_request(params=nil)
      params = { :id => 55 } if !params
      get :add_comment, params
    end

    it 'should render the template "add_comment"' do
      make_request
      response.should render_template('shared/add_comment')
    end

  end


  describe 'POST #add_comment' do

    before do
      @mock_user = mock_model(User)
      @mock_model = mock_model(Campaign, :visible? => true,
                                            :editable? => true)
      Campaign.stub!(:find).and_return(@mock_model)
      @expected_notice = "Please sign in or create an account to add your comment to this issue"
    end

    def make_request params
      post :add_comment, params
    end

    def default_params
      { :id => 55,
        :comment => { :commentable_id => 55,
                      :commentable_type => 'Campaign'} }
    end

    it_should_behave_like "an action that receives a POSTed comment"

  end

  describe 'POST #complete' do

    before do
      @user = mock_model(User, :id => 55,
                               :name => "Test User",
                               :answered_ever_reported? => true)
      @default_params = { :id => 55 }
      @controller.stub!(:current_user).and_return(@user)
      @mock_campaign = mock_model(Campaign, :visible? => true,
                                            :editable? => true,
                                            :status => :confirmed,
                                            :initiator => @user,
                                            :status= => true,
                                            :save => true,
                                            :send_questionnaire= => nil,
                                            :status_code => 3)
      Campaign.stub!(:find).and_return(@mock_campaign)
      @expected_access_message = :campaigns_complete_access_message
      @expected_wrong_user_message = 'mark this problem as fixed'
    end

    def make_request(params)
      post :complete, params
    end

    it_should_behave_like "an action that requires the campaign initiator"

    it 'should set the campaign status to complete and save it' do
      @mock_campaign.should_receive(:status=).with(:fixed)
      @mock_campaign.should_receive(:save)
      make_request(@default_params)
    end

    it 'should set the "send_questionnaire" flag on the campaign to false' do
      @mock_campaign.should_receive(:send_questionnaire=).with(false)
      @mock_campaign.should_receive(:save)
      make_request(@default_params)
    end

    describe 'if the user has answered the "have you ever reported an issue before" question' do

      before do
        @user.stub!(:answered_ever_reported?).and_return(true)
      end

      it 'should redirect to the campaign page' do
        make_request(@default_params)
        response.should redirect_to(campaign_url(@mock_campaign))
      end

    end

    describe 'if the user has not answered the "have you ever reported an issue before" question' do

      before do
        @user.stub!(:answered_ever_reported?).and_return(false)
      end

      it 'should add the old status code to the session flash' do
        make_request(@default_params)
        flash[:old_status_code].should == 3
      end

      it 'should redirect to the questionnaire for fixed issues' do
        make_request(@default_params)
        response.should redirect_to(questionnaire_fixed_url(:id => @mock_campaign.id, :type => 'Campaign'))
      end
    end

  end

  describe 'GET #add_photos' do

    before do
      @user = mock_model(User, :id => 55, :name => "Test User")
      @default_params = { :id => 55 }
      @controller.stub!(:current_user).and_return(@user)
      @mock_campaign = mock_model(Campaign, :visible? => true,
                                            :editable? => true,
                                            :status => :confirmed,
                                            :initiator => @user,
                                            :campaign_photos => [],
                                            :friendly_id_status => mock('friendly', :best? => true))
      @mock_campaign.campaign_photos.stub!(:build).and_return(true)
      Campaign.stub!(:find).and_return(@mock_campaign)
      @expected_wrong_user_message = 'add photos to this problem page'
      @expected_access_message = :campaigns_add_photos_access_message
    end

    def make_request(params)
      get :add_photos, params
    end

    it_should_behave_like "an action that requires the campaign initiator"

    it 'should render the "add_photos" template' do
      make_request(@default_params)
      response.should render_template("add_photos")
    end

  end

  describe 'POST #add_photos' do

    before do
      @user = mock_model(User, :id => 55, :name => "Test User")
      @default_params = { :id => 55 }
      @controller.stub!(:current_user).and_return(@user)
      @campaign_photo = mock_model(CampaignPhoto, :new_record? => true)
      @mock_campaign = mock_model(Campaign, :visible? => true,
                                            :editable? => true,
                                            :status => :confirmed,
                                            :initiator => @user,
                                            :campaign_photos => [@campaign_photo])
      Campaign.stub!(:find).and_return(@mock_campaign)
      @expected_access_message = :campaigns_add_photos_access_message
      @expected_wrong_user_message = 'add photos to this problem page'
    end

    def make_request(params)
      post :add_photos, params
    end

    it_should_behave_like "an action that requires the campaign initiator"

    describe 'if the campaign (with associated photo) can be saved' do

      before do
        @mock_campaign.stub!(:update_attributes).and_return(true)
      end

      it 'should redirect to the campaign url' do
        make_request(@default_params)
        response.should redirect_to(campaign_url(@mock_campaign))
      end

    end

    describe 'if the campaign (with associated photo) cannot be saved' do

      before do
        @mock_campaign.stub!(:update_attributes).and_return(false)
      end

      it 'should render the add_photos template' do
        make_request(@default_params)
        response.should render_template("add_photos")
      end

      it 'should assign the campaign photo to the template' do
        make_request(@default_params)
        assigns[:campaign_photo].should == @campaign_photo
      end

    end
  end

  describe 'POST #add_update' do

    before do
      @user = mock_model(User, :id => 55, :name => 'Test User')
      @controller.stub!(:current_user).and_return(@user)
      @mock_update = mock_model(CampaignUpdate, :save => true,
                                                :is_advice_request? => false,
                                                :user= => true)
      @mock_updates = mock('campaign updates', :build => @mock_update)
      @mock_events = mock('campaign events', :create! => true)
      @mock_campaign = mock_model(Campaign, :supporters => [],
                                            :title => 'A test title',
                                            :visible? => true,
                                            :editable? => true,
                                            :add_supporter => true,
                                            :status => :confirmed,
                                            :campaign_updates => @mock_updates,
                                            :campaign_events => @mock_events,
                                            :initiator => @user)
      Campaign.stub!(:find).and_return(@mock_campaign)
      @expected_wrong_user_message = 'ask for advice on this problem'
      @expected_access_message = :campaigns_add_update_access_message
      @default_params = { :id => 55, :update_id => '33' }
    end

    def make_request(params)
      post :add_update, params
    end

    it_should_behave_like "an action that requires the campaign initiator"

    it 'should redirect to the campaign url' do
      make_request(:id => 55)
      response.should redirect_to(campaign_url(@mock_campaign))
    end

    it 'should try and save the new campaign update' do
      @mock_updates.should_receive(:build).and_return(@mock_update)
      @mock_update.should_receive(:save).and_return(true)
      make_request(:id => 55)
    end

    describe 'if the update was successfully saved' do

      before do
        @mock_update.stub!(:save).and_return(true)
      end

      it 'should display a notice' do
        make_request(:id => 55)
        flash[:notice].should == 'Your update has been added.'
      end

      it "should add a 'campaign_update_added' event" do
        @mock_events.should_receive(:create!).with(:event_type => 'campaign_update_added',
                                                   :described => @mock_update)
        make_request(:id => 55)
      end

    end

    describe 'when handling JSON request' do

      it 'should return a json hash with a key "html"' do
        post :add_update, {:id => 55, :format => 'json'}
        json_hash = JSON.parse(response.body)
        json_hash['html'].should_not be_nil
      end

    end

  end

  describe 'POST #leave' do

    describe 'if there is a current user who is a campaign supporter' do

      before do
        @user = mock_model(User)
        @controller.stub!(:current_user).and_return(@user)
        @campaign = mock_model(Campaign, :editable? => true,
                                         :visible? => true,
                                         :title => 'A test campaign',
                                         :remove_supporter => nil)
        Campaign.stub!(:find).and_return(@campaign)
      end

      def make_request
        post :leave, :id => 55
      end

      it 'should remove the campaign supporter' do
        @campaign.should_receive(:remove_supporter).with(@user)
        make_request
      end

      it 'should show a notice saying that the user is no longer a supporter' do
        make_request
        flash[:notice].should == 'You are no longer a supporter of this campaign.'
      end

      it 'should redirect to the campaign url' do
        make_request
        response.should redirect_to(campaign_path(@campaign))
      end

    end

  end

  describe 'POST #join' do

    before do
      @mock_campaign = mock_model(Campaign, :supporters => [],
                                            :title => 'A test title',
                                            :visible? => true,
                                            :editable? => true,
                                            :add_supporter => true)
      Campaign.stub!(:find).and_return(@mock_campaign)
      @default_params = { :id => 44, :user_id => '55' }
    end

    def make_request(params=@default_params)
      post :join, params
    end

    describe 'when there is a current user' do

      before do
        @user = mock_model(User, :id => 55)
        @controller.stub!(:current_user).and_return(@user)
      end

      it 'should make the user a confirmed campaign supporter' do
        @mock_campaign.should_receive(:add_supporter).with(@user, confirmed=true)
        make_request(@default_params)
      end

      it 'should redirect them to the campaign URL' do
        make_request(@default_params)
        response.should redirect_to(campaign_url(@mock_campaign))
      end

    end

    describe 'when there is no current user' do

      it 'should store the next action in the session' do
        @controller.should_receive(:data_to_string)
        make_request
      end


      describe 'if the request asks for json' do

        it 'should return a hash with the success key set to true' do
        make_request(@default_params.update(:format => 'json'))
        json_hash = JSON.parse(response.body)
        json_hash['success'].should == true
        end

        it 'should return a hash with the "requires login" flag set to true' do
          make_request(@default_params.update(:format => 'json'))
          json_hash = JSON.parse(response.body)
          json_hash['requires_login'].should == true
        end

        it 'should return a hash with a notice key giving a notice to show to the user' do
          make_request(@default_params.update(:format => 'json'))
          json_hash = JSON.parse(response.body)
          json_hash['notice'].should == 'Please sign in or create an account to help get this problem fixed'
        end

      end

      describe 'if the request asks for html' do

        it 'should redirect to the login page' do
          make_request(@default_params)
          response.should redirect_to(login_url)
        end

        it 'should display a notice that the user needs to login to join the campaign' do
          make_request(@default_params)
          flash[:notice].should == 'Please sign in or create an account to help get this problem fixed'
        end

      end

    end

  end


end
