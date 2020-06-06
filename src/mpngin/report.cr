require "csv"

module Mpngin
  class Report
    def initialize
      @result = [] of Hash(String, String | Nil)
    end

    def call
      # ameba:disable Lint/UselessAssign
      _cursor, short_link_keys = redis_client.scan(0, "*:url")

      @result = short_link_keys.as(Array(Redis::RedisValue)).map do |key|
        # ameba:disable Lint/UselessAssign
        request_key, _namespace = key.as(String).split(":")

        {
          "short_link"    => "#{SHORT_URL}/#{request_key}",
          "expanded_link" => redis_client.get("#{request_key}:url"),
          "request_count" => redis_client.get("#{request_key}:requests").to_s,
        }
      end
    end

    def to_csv
      call

      CSV.build(quoting: CSV::Builder::Quoting::ALL) do |csv|
        csv.row "Short Link", "Expanded Link", "Request Count"

        @result.as(Array).each do |link|
          csv.row link["short_link"], link["expanded_link"], link["request_count"]
        end
      end
    end

    private def redis_client
      @redis_client ||= Redis.new(database: REDIS_DB)
    end
  end
end
