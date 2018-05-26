require "dotenv"
require "json"
require "kemal"
require "redis"

require "./mpngin/*"

Dotenv.load

module Mpngin
  FALLBACK_URL = ENV["FALLBACK_URL"].to_s
  REDIS_DB = ENV["REDIS_DATABASE"].to_i
  SECRET_TOKEN = ENV["SECRET_TOKEN"].to_s
  SHORT_URL = ENV["SHORT_URL"].to_s

  class Auth
    def self.authorized?(request)
      auth_header = request.headers.fetch("Authorization", nil)
      valid_token?(split_header(auth_header))
    end

    def self.secret_authorized?(request)
      auth_header = request.headers.fetch("Authorization", nil)
      valid_secret?(split_header(auth_header))
    end

    def self.valid_token?(token : String)
      return false if token.nil?
      Redis.new(database: REDIS_DB).exists("#{token}:application") == 1
    end

    def self.valid_token?(token)
      false
    end

    def self.valid_secret?(token : String)
      SECRET_TOKEN == token
    end

    def self.valid_secret?(token)
      false
    end

    def self.split_header(header : String)
      header.split(" ")[1]
    end

    def self.split_header(header)
      nil
    end
  end

  get "/" do |env|
    env.redirect FALLBACK_URL
  end

  post "/application" do |env|
    authorized = Auth.secret_authorized?(env.request)
    unless authorized
      halt env, status_code: 401, response: "Not authorized"
    end

    app_key = Random.new.hex(16)
    redis = Redis.new(database: REDIS_DB)
    redis.set("#{app_key}:application", 1)

    env.response.status_code = 201
    env.response.content_type = "text/plain; charset=utf-8"
    app_key
  end

  post "/" do |env|
    authorized = Auth.authorized?(env.request)
    unless authorized
      halt env, status_code: 401, response: "Not authorized"
    end

    redis = Redis.new(database: REDIS_DB)
    key_available = false
    redirect_url = env.params.body.fetch("redirect_url", nil)

    if redirect_url.nil?
      halt env, status_code: 422, response: "Must provide redirect_url param."
    end

    until key_available
      key = Random.new.hex(3)
      key_available = redis.exists(key) == 0
    end

    redis.set("#{key}:url", redirect_url.strip)
    redis.set("#{key}:requests", 0)

    env.response.status_code = 201
    env.response.content_type = "text/plain; charset=utf-8"
    "#{SHORT_URL}/#{key}"
  end

  get "/:short_code" do |env|
    redis = Redis.new(database: REDIS_DB)
    key = env.params.url["short_code"].strip
    result_url = redis.get("#{key}:url")

    if result_url.nil?
      env.response.content_type = "text/plain; charset=utf-8"
      "¯\\_(ツ)_/¯"
    else
      redis.incr("#{key}:requests")
      env.redirect result_url
    end
  end

  get "/:short_code/stats" do |env|
    authorized = Auth.authorized?(env.request)
    unless authorized
      halt env, status_code: 401, response: "Not authorized"
    end

    redis = Redis.new(database: REDIS_DB)
    key = env.params.url["short_code"].strip
    result_url = redis.get("#{key}:url")
    env.response.content_type = "text/plain; charset=utf-8"

    if result_url.nil?
      "¯\\_(ツ)_/¯"
    else
      redis.get("#{key}:requests")
    end
  end

  serve_static false
  Kemal.run
end
