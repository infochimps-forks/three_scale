require 'digest'
require 'base64'

#!/usr/bin/env ruby
module ThreeScale
  class ApiToken
    # Customer's username
    attr_reader :username
    # obscure the token generation.
    def salt() 'monkeynutzzSfaKT7CwImCHCH8Ow' end
    # Memoize the creation time.
    def timestamp() @timestamp ||= Time.now.strftime("%Y%m%d%H%M%SZ") end

    def initialize username
      @username = username.to_s
      self.timestamp
      #raise "Username too short: '#{username}'" unless (self.username.length > MAX_USERNAME_LEN) && (api_name.length > MAX_USERNAME_LEN)
      raise "WTF bad salt" unless salt.length > 10
    end

    # Identifier for customer: max 15chars, \w only, lowercase
    def api_name
      return @api_name if @api_name
      sanitized = @username.gsub(/[\W_]+/, '_')
      @api_name ||= sanitized[0..15]
    end

    # Salt used in ID generation
    def salted_name
      [api_name,rand_salt].join('--')
    end

    # SHA1 hash in compact form
    def sha1_base64
      str = Base64.encode64(Digest::SHA1.digest(salted_name)).strip
      str.tr('+/', '-_').gsub(/=/,'')
  end

  # SHA1 hash in salted form
  def sha1_hex
    Digest::SHA1.hexdigest(salted_name)
  end

  def apikey
    api_name + "-" + sha1_base64[0..-3]+'69'
  end

  #generates a random salt based upon the characters returned by salt()
  def rand_salt
    result  = ''
    salt().length.times {result << salt()[rand(salt().length),1]}
    result
  end

end
end
