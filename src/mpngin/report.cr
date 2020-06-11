require "csv"

module Mpngin
  class Report
    def initialize
      @result = [] of Hash(String, String | Nil)
    end

    def call
      cursor = "0"

      loop do
        cursor, short_link_keys = redis_client.scan(cursor, "*:url")

        short_link_keys.as(Array(Redis::RedisValue)).each do |key|
          # ameba:disable Lint/UselessAssign
          request_key, _namespace = key.as(String).split(":")

          @result << {
            "short_link"    => "#{SHORT_URL}/#{request_key}",
            "expanded_link" => redis_client.get("#{request_key}:url"),
            "request_count" => redis_client.get("#{request_key}:requests").to_s,
          }
        end

        break if cursor == "0"
      end

      @result
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
      @redis_client ||= Redis.new(url: REDIS_URL)
    end
  end
end
