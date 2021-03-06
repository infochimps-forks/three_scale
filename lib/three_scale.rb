require 'rubygems'
require 'net/http'
require 'nokogiri'
require 'crack'
# begin
#   require 'activesupport'
# rescue LoadError
#   require "active_support"
# end

module ThreeScale
  class << self

    attr_accessor :provider_key, :host

    def configure
      yield self
      #Default host for V1.0 of the 3scale API
      self.host ||= 'server.3scale.net'
    end

  end

  autoload :User,     'three_scale/user'
  autoload :Request,  'three_scale/request'
  autoload :Metrics,  'three_scale/metrics'
  autoload :ApiToken, 'three_scale/api_token'
end
