# a demo of facebook server side authentication
# https://developers.facebook.com/docs/facebook-login/manually-build-a-login-flow

api = RestCore::Facebook.new(app_id: ENV['FACEBOOK_KEY'], secret: ENV['FACEBOOK_SECRET'])
redirect_url ='http://issue-social.dev/facebook/callback'

Facebook = Cuba.new do
  on 'callback' do
    token = api.authorize!(code: req.params['code'], redirect_uri: redirect_url)
    token['expired_at'] = (Time.now + token.delete('expires').to_i).httpdate

    template = Mote.parse(<<-HTML, self, [:token])
      % for k,v in token
      {{k}}: {{v}}<br>
      % end
    HTML

    res.write template.call(token: token)
  end

  on default do
    login_url = api.authorize_url(redirect_uri: redirect_url)
    res.redirect login_url
  end
end
