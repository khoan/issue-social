require 'cuba'
require 'logger'
require 'mote'
require 'rest-more'
require 'time'

Log = Logger.new('debug.log')

IO.read('env.sh').scan(/(.*?)="?(.*)"?$/).each do |key, value|
  ENV[key] ||= value
end

class Cuba
  def render template_path, vars={}
    template = Mote.parse(IO.read(template_path), self, vars.keys)
    res.write template.call(vars)
  end
end

Cuba.define do
  on 'facebook' do
    require_relative 'facebook'
    run Facebook
  end
end
