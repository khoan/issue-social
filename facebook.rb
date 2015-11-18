# Facebook authentication flow
# https://developers.facebook.com/docs/facebook-login/manually-build-a-login-flow
#
# /auth   a demo of login flow
# /demo   a demo of login flow within iframe 

Facebook = Cuba.new do
  on 'demo' do
    render 'template/facebook/demo.html'
  end

  api = RestCore::Facebook.new(app_id: ENV['FACEBOOK_KEY'], secret: ENV['FACEBOOK_SECRET'], log_method: Log.method(:info))
  default_redirect_url ='http://issue-social.dev/facebook/callback'

  on 'profile' do
    user = api.get(req.cookies['fb_id'], access_token: api.secret_access_token)
    render 'template/facebook/profile.html', user: user
  end

  on 'callback' do
    token = api.authorize!(code: req.params['code'], redirect_uri: default_redirect_url)
    token['expired_at'] = (Time.now + token.delete('expires').to_i).httpdate

    debug = api.get('debug_token', input_token: token['access_token'], access_token: api.secret_access_token)

    res.set_cookie('fb_id', value: debug['data']['user_id'], expires: Time.now+60*60*24, path: '/', domain: '.issue-social.dev')

    render 'template/facebook/callback.html', token: token, debug: debug
  end

  on 'auth' do
    login_url = api.authorize_url(redirect_uri: default_redirect_url)
    res.redirect login_url
  end
end
