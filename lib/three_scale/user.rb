module ThreeScale
  class User
    include ThreeScale::Request
    include ThreeScale::Metrics

    attr_accessor :apikey,:email,:first_name,:last_name, :plan, :username
    attr_reader :username, :plan

    def self.find(username)
      user = new(username)
      if user.has_account?
        user.plan = user.account["contract"]["plan"]["name"]
        user.apikey = user.account["contract"]['user_key']
        #currently no way to pull in existing user metadata like email,first_name,last_name...
        user
      else
        user = nil
        #Could not find the given username
        false
      end
    end

    def self.find_or_create(username, options = { })
      user = new(username,options)
      if user.has_account?
        user.plan = user.account["contract"]["plan"]["name"]
        user.apikey = user.account["contract"]['user_key']
        #currently no way to pull in existing user metadata like email,first_name,last_name...
        user
      else
        user.signup!
      end
    end

    def initialize username = nil, options = { }
      @username     = username or raise "Must supply a username!"
      @apikey       = options[:apikey] || generate_apikey
      @first_name   = options[:first_name]
      @last_name    = options[:last_name]
      @email        = options[:email]
      @plan         = options[:plan] || "Baboon"
      @provider_key = ThreeScale.provider_key or raise "Must supply a provider key to use the 3scale API!"
      @host         = options[:host] || ThreeScale.host
    end

    #GET /plans.xml
    #Returns a array of available plans (plans). Each plan is a hash with two
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
      path = "/plans/#{plan_id}/signup.xml"
      post(path, {
          :user_key => apikey,
          "user[username]" => username,
          "user[email]" => email,
          "user[first_name]" => first_name,
          "user[last_name]" => last_name
        })
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
    # Rolls back to the old key if something goes wrong during the update
    def regenerate_apikey!(apikey=nil)
      old_key = @apikey
        @apikey = apikey || generate_apikey
      resp = put("/users/#{username}.xml",:user_key => @apikey)
      if resp.success?
        @apikey
      else
        @apikey = old_key
        resp
      end
    end

    #POST to /buyer/plans/plan_id/change.xml
    #PUT /users/username.xml

    def update!
      @authorize = nil
       update_plan! &&
        put("/users/#{username}.xml", {
          :user_key => apikey,
          "user[email]" => email,
          "user[first_name]" => first_name,
          "user[last_name]" => last_name
        })
    end

    def update_plan!
      post("/buyer/plans/#{plan_id}/change.xml",:username => username)
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

    def plan_id
      plan_id = 0
      plans.each do |plan|
        if plan.first == @plan.downcase.gsub(" ","_").to_sym
          plan_id = plan.last['id']
          @plan = plan.last['name']
        end
      end
      raise "Invalid plan #{@plan}, try one of [#{plans.keys.join(",")}]" if plan_id == 0
      plan_id
    end

    def generate_apikey
      ApiToken.new(username).apikey
    end

  end
end
