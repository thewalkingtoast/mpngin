require "dotenv"

Dotenv.load(filename: ".env.test")

require "spec"
require "spec-kemal"
require "../src/mpngin"

def make_redis
  Redis.new(database: ENV["REDIS_DATABASE"].to_i)
end

def flush_redis
  make_redis.flushdb
end

def register_test_app
  make_redis.set("#{test_app_key}:application", 1)
end

def test_app_authorization
  "bearer #{test_app_key}"
end

def test_app_key
  "93706092ace50842de4b33cd1a7b3aec"
end

Spec.before_each do
  flush_redis
  register_test_app
end
