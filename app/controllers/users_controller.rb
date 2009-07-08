class UsersController < ApplicationController
  def self.consumer
    OAuth::Consumer.new("cHU2AwB44eLzeZuwLkTA", "RBvNufBf3T22iPmPP406UecSgkoRZycguGoHELfU4", {:site => 'http://localhost:3000'})
  end

  def create
    @request_token = UsersController.consumer.get_request_token
    session[:request_token] = @request_token.token
    session[:request_token_secret] = @request_token.secret
    redirect_to @request_token.authorize_url
  end

  def callback
    @request_token = OAuth::RequestToken.new(UsersController.consumer, session[:request_token], session[:request_token_secret])
    @access_token = @request_token.get_access_token
    @response = UsersController.consumer.request(:get, '/oauth/verify_credentials', @access_token, {:scheme => :query_string})

    case @response
    when Net::HTTPSuccess
      user_info = JSON.parse(@response.body)
      unless user_info['username']
        flash[:notice] = 'authentication failed'
        redirect_to :action => :index
        return
      end

      @user = User.new(:username => user_info['username'], :token => @access_token.token, :secret => @access_token.secret)
      @user.save!
      session['user'] = @user.username
      render :text => @user.to_json
    else
      # failure
      flash[:notice] = 'authentication failed'
      redirect_to :action => :index
      return
    end
  end

  def create_project
    @user = User.find_by_username(session['user'])
    @access_token = OAuth::AccessToken.new(UsersController.consumer, @user.token, @user.secret)
    @response = UsersController.consumer.request(:post, '/api/v1/projects.xml', @access_token, {:scheme => :query_string},
                                                 {'project[title]' => 'Valid Project',
                                                  'project[category_id]' => 1,
                                                  'project[description]' => 'The most valid project you have ever seen!',
                                                  'project[requirements]' => 'Lots of validity.',
                                                  'project[start_date]' => Time.now,
                                                  'project[max_experts]' => 5,
                                                  'expert_payment_plan[amount]' => 10,
                                                  'expert_payment_plan[payment_type]' => 'fixed'})
    render :xml => @response.body
  end  
end
