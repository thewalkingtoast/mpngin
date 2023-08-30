require "redis"
require "uri"

module Mpngin
  class Repository
    getter store : Redis::PooledClient

    def initialize
      @store = Redis::PooledClient.new(url: REDIS_URL)
    end

    def store_application
      key_available = false
      until key_available
        app_key = Random.new.hex(16)
        key_available = store.exists(app_key) == 0
      end

      store.set("#{app_key}:application", 1)
      app_key
    end

    def store_short_link(to, from = SHORT_URL)
      from_uri = URI.parse(from.to_s.strip.downcase).normalize
      clean_from_host = from_uri.host
      clean_scheme_host = from_uri.scheme
      clean_to = to.to_s.strip

      key_available = false
      until key_available
        short_code = Random::Secure.hex(SHORT_ID_SIZE)
        key = "#{clean_from_host}:#{short_code}"
        url_key = "#{key}:url"
        key_available = store.exists(url_key) == 0
      end

      store.mset({"#{key}:url" => clean_to, "#{key}:requests" => 0})

      {
        "created_at"    => Time.utc.to_s("%Y-%m-%d %H:%M:%S %:z"),
        "expanded_link" => clean_to,
        "request_count" => 0,
        "short_code"    => short_code,
        "short_link"    => "#{clean_scheme_host}://#{clean_from_host}/#{short_code}",
      }
    end

    def fetch_short_link(short_code)
      suffix = ":#{short_code}"
      matching_keys = store.keys("*#{suffix}:url").as(Array(Redis::RedisValue))

      return nil if matching_keys.size == 0

      url_key = matching_keys.first.to_s

      requests_key = url_key.as(String).gsub(":url", ":requests")
      short_url = url_key.as(String).gsub(":#{short_code}:url", "")

      {
        "expanded_link" => store.get(url_key),
        "report_date"   => Time.utc.to_s("%Y-%m-%d %H:%M:%S %:z"),
        "request_count" => store.get(requests_key).to_s,
        "short_code"    => short_code,
        "short_link"    => "https://#{short_url}/#{short_code}",
      }
    end

    def increment_request_count(short_code)
      suffix = ":#{short_code}"
      url_key = store.keys("*#{suffix}:url").as(Array(Redis::RedisValue)).first.to_s
      requests_key = url_key.as(String).gsub(":url", ":requests")
      store.incr(requests_key)
    end
  end
end
