# Facebook authentication flow
# https://developers.facebook.com/docs/facebook-login/manually-build-a-login-flow
#
# /auth   a demo of login flow
# /demo   a demo of login flow within iframe, and popup

Facebook = Cuba.new do
  on 'demo' do
    render 'template/facebook/demo.html'
  end

  on 'id' do
    on get do
      render 'template/facebook/id.html'
    end

    on post do
      url = "https://facebook.com/#{req.params['username']}"
      client = RestCore::Universal.new
      response = client.get(url)

      id = response[%r{<meta property="al:android:url" content="fb://profile/([^"]+)"}, 1]

      res.write id
    end
  end

  api = RestCore::Facebook.new(app_id: ENV['FACEBOOK_KEY'], secret: ENV['FACEBOOK_SECRET'], log_method: Log.method(:info))
  default = {
    redirect_uri: 'http://issue-social.dev/facebook/callback',
    permissions: 'email,user_birthday,user_relationships,user_location',
    fields: 'id,name,email,gender,location,age_range,birthday,location,relationship_status',
  }

  on 'profile' do
    fields = req.params['fields'] || default[:fields]
    user = api.get(req.cookies['fb_id'], access_token: api.secret_access_token, fields: fields)
    render 'template/facebook/profile.html', user: user
  end

  on 'callback' do
    token = api.authorize!(code: req.params['code'], redirect_uri: default[:redirect_uri])
    token['expired_at'] = (Time.now + token.delete('expires').to_i).httpdate

    debug = api.get('debug_token', input_token: token['access_token'], access_token: api.secret_access_token)

    res.set_cookie('fb_id', value: debug['data']['user_id'], expires: Time.now+60*60*24, path: '/', domain: '.issue-social.dev')

    # method 1 - go back to iOS homescreen webapp fullscreen
    res.redirect 'http://issue-social.dev/facebook/demo' #'http://googel.com'

    # method 2 - use <meta> to redirect
    #render 'template/facebook/callback.html', token: token, debug: debug
  end

  on 'auth' do
    scope = req.params['scope'] || default[:permissions]
    login_url = api.authorize_url(redirect_uri: default[:redirect_uri], scope: scope)
    res.redirect login_url
  end
end
