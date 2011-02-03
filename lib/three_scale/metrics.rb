module ThreeScale
  module Metrics

    def hour_limit
      limit :hour
    end

    def hour_usage
      usage :hour
    end

    def month_limit
      limit :month
    end

    def month_usage
      usage :month
    end

    private

    #3scale just returns an array which holds all the metrics, hopefully this will
    #change to be less brittle.  Newly added metrics are pushed onto the end of
    #the array.  I try to add the metrics in the order of [hour, month]
    def limit period
      index = period == :hour ? 0 : 1
      begin
        account['contract']['status']['usage'][index]['max_value']
      rescue NoMethodError #The key is out of sync with 3scale
        "Unavailable"
      end
    end

    def usage period
      index = period == :hour ? 0 : 1
      begin
        account['contract']['status']['usage'][index]['current_value']
      rescue NoMethodError #The key is out of sync with 3scale
        "Unavailable"
      end
    end

  end
end

