require 'cuba'
require 'logger'
require 'mote'
require 'rest-more'
require 'time'
require 'yaml'

Log = Logger.new('debug.log')
ENV.update( YAML.load_file('.env') ) { |name, old, new| old || new.to_s }

Cuba.define do
  on 'facebook' do
    api = RestCore::Facebook.new(app_id: ENV['FACEBOOK_KEY'], secret: ENV['FACEBOOK_SECRET'])
    redirect_url ='http://issue-social.dev/facebook/callback'

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
end

run Cuba
