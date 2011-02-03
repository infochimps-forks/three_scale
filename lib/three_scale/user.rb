#########USAGE###########

# new_user = ThreeScale::User.new("foobar", :tier => "Silverback")

#------An valid apikey will be created for the username provided. Only the username is
#------required, the tier will default to Baboon if none is specified.

# new_user.signup!

#------user is signed up as a Silverback in 3scale

# new_user.tier = "baboon"
# new_user.update!

#------user is now a Baboon in 3scale

# new_user.regenerate_apikey!

#------A new apikey is generated and pushed up to 3scale

# new_user.cancel!

#------user is destroyed in 3scale

module ThreeScale
  class User
    include ThreeScale::Request
    include ThreeScale::Metrics

    attr_accessor :apikey,:email,:first_name,:last_name, :tier, :username
    attr_reader :username, :tier

    def self.find(username)
      user = new(username)
      if user.has_account?
        user.tier = user.account["contract"]["plan"]["name"]
        user.apikey = user.account["contract"]['user_key']
        #currently no way to pull in existing user metadata like email,first_name,last_name...
        user
      else
        user = nil
        #Could not find the given username
        false
      end
    end

    def initialize username = nil, options = { }
      @username     = username or raise "Must supply a username!"
      @apikey       = options[:apikey] || generate_apikey
      @first_name   = options[:first_name]
      @last_name    = options[:last_name]
      @email        = options[:email]
      @tier         = options[:tier] || "Baboon"

      @provider_key = ThreeScale.provider_key or raise "Must supply a provider key to use the 3scale API!"
      @host         = options[:host] || ThreeScale.host
    end

    def tier_id
      plan_id = 0
      plans.each do |plan|
        if plan.first == @tier.downcase.gsub(" ","_").to_sym
          plan_id = plan.last['id']
          @tier = plan.last['name']
        end
      end
      raise "Invalid tier #{@tier}, try one of [#{plans.keys.join(",")}]" if plan_id == 0
      plan_id
    end

    #GET /plans.xml
    #Returns a array of available plans (tiers). Each plan is a hash with two
    #keys: {'name','id'}

    def plans
      get("/plans.xml").body['plans'].inject({}) do |plan_names,plan| plan_names.merge!(plan["name"].downcase.gsub(" ","_").to_sym => plan); end
    end

    #POST /plans/plan_id/signup.xml
    #
    # @params@
    # provider_key
    # user[username]
    # user key
    # -OPTIONAL-
    # user[email]
    # user[first_name]
    # user[last_name]
    #

    def signup!
      if has_account?
        update!
      else
        path = "/plans/#{tier_id}/signup.xml"
        post(path, {
            :user_key => apikey,
            "user[username]" => username,
            "user[email]" => email,
            "user[first_name]" => first_name,
            "user[last_name]" => last_name
          })
      end
    end

    #DELETE /users/[username].xml
    #
    # @params@
    # provider_key
    #

    def cancel!
      delete("/users/#{username}.xml")
    end

    #PUT /users/username.xml
    # @params@
    #
    # apikey (optional) - key to use instead of a new random apikey
    #
    # @returns@
    # The new apikey if successful, otherwise the previous key
    def regenerate_apikey!(apikey=nil)
      old_key = @apikey
      begin
        @apikey = apikey || generate_apikey
        put("/users/#{username}.xml",:user_key => @apikey)
      rescue => error
        @apikey = old_key
      end
      @apikey
    end

    #POST to /buyer/plans/plan_id/change.xml
    #PUT /users/username.xml

    def update!
      @authorize = nil
       update_tier! &&
        put("/users/#{username}.xml", {
          :user_key => apikey,
          "user[email]" => email,
          "user[first_name]" => first_name,
          "user[last_name]" => last_name
        })
    end

    def update_tier!
      post("/buyer/plans/#{tier_id}/change.xml",:username => username)
    end

    #GET to /buyer/contract.xml?
    #
    # @params@
    # provider_key
    # username
    #

    def has_account?
      get("/buyer/contract.xml",:username => username).success?
    end

    #GET to /buyer/contract.xml?
    #
    # @params@
    # provider_key
    # username
    #
    def account
      get("/buyer/contract.xml",:username => username).body
    end

    private

    def generate_apikey
      ApiToken.new(username).apikey
    end

  end
end
