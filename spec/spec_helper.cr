require "dotenv"

Dotenv.load(filename: ".env.test")

require "uri/params"
require "spec"
require "spec-kemal"
require "../src/mpngin"

REDIS_CONNECTION = Redis.new(url: ENV["REDIS_URL"].to_s)

def redis
  REDIS_CONNECTION
end

def flush_redis
  redis.flushdb
end

def register_test_app
  redis.set("#{test_app_key}:application", 1)
end

def test_app_authorization
  "bearer #{test_app_key}"
end

def test_app_key
  "93706092ace50842de4b33cd1a7b3aec"
end

def host
  ENV["SHORT_URL"]
end

def hostname
  URI.parse(host.downcase).normalize.host
end

def csv_report_name
  ENV["LINK_REPORT_CSV_NAME"]
end

Spec.before_each do
  flush_redis
  register_test_app
end
