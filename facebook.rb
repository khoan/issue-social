# Facebook authentication flow
# https://developers.facebook.com/docs/facebook-login/manually-build-a-login-flow
#
# /auth   a demo of login flow
# /demo   a demo of login flow within iframe 

api = RestCore::Facebook.new(app_id: ENV['FACEBOOK_KEY'], secret: ENV['FACEBOOK_SECRET'])
default_redirect_url ='http://issue-social.dev/facebook/callback'

Facebook = Cuba.new do
  on 'demo' do
    template = Mote.parse(<<HTML, self)
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Facebook iOS home screen App demo</title>
</head>
<body>
  <a class="fb-connect iframe" href="#">connect via iframe</a>
  <a class="fb-connect popup" href="#">connect via popup</a>

  <script>
    (function init(connect, iframe) {
      var connect = document.querySelectorAll(".fb-connect"), i;
      for(i = 0; i < connect.length; ++i) {
        connect[i].addEventListener("click", function(event) {
          var classList = event.target.classList;
          event.preventDefault();

          if (classList.contains("iframe")) {
            iframe = document.createElement("iframe");
            iframe.src = "http://issue-social.dev/facebook/auth";
            document.body.appendChild(iframe);
          } else if (classList.contains("popup")) {
            window.open("http://issue-social.dev/facebook/auth");
          }
        });
      }

      window.addEventListener("message", function(message) {
        console.log('----> child says', message);
      }, false);
    })();
  </script>
</body>
</html>
HTML

    res.write template.call
  end

  on 'callback' do
    token = api.authorize!(code: req.params['code'], redirect_uri: default_redirect_url)
    token['expired_at'] = (Time.now + token.delete('expires').to_i).httpdate

    template = Mote.parse(<<HTML, self, [:token])
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Facebook callback</title>
</head>
<body>
  % for k,v in token
  {{k}}: {{v}}<br>
  % end

  <script>
    (function init(parent) {
      if (window.opener) {
        parent = window.opener;
      } else if (window.parent) {
        parent = window.parent;
      }

      parent.postMessage({{JSON.dump token}}, "*");
    })();
  </script>
</body>
</html>
HTML

    res.write template.call(token: token)
  end

  on 'auth' do
    login_url = api.authorize_url(redirect_uri: default_redirect_url)
    res.redirect login_url
  end
end
