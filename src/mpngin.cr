require "dotenv"

Dotenv.load

require "json"
require "kemal"
require "redis"

require "./mpngin/constants"
require "./mpngin/version"
require "./mpngin/auth"
require "./mpngin/report"

module Mpngin
  get "/" do |env|
    env.redirect FALLBACK_URL
  end

  get "/health_check" do |env|
    env.response.content_type = "text/plain; charset=utf-8"
    "I am a-okay."
  end

  post "/application" do |env|
    authorized = Auth.secret_authorized?(env.request)
    unless authorized
      halt env, status_code: 401, response: "Not authorized"
    end

    key_available = false
    redis = Redis.new(url: REDIS_URL)

    until key_available
      app_key = Random.new.hex(16)
      key_available = redis.exists(app_key) == 0
    end

    redis.set("#{app_key}:application", 1)

    env.response.status_code = 201
    env.response.content_type = "text/plain; charset=utf-8"
    app_key
  end

  get "/report.:format" do |env|
    authorized = Auth.secret_authorized?(env.request)
    unless authorized
      halt env, status_code: 401, response: "Not authorized"
    end

    report = Report.new
    format = (env.params.url["format"] || "json").to_s.strip.downcase

    case format
    when "csv"
      env.response.status_code = 200
      env.response.content_type = "application/octet-stream; charset=utf-8"
      env.response.headers.add("Content-Disposition", "attachment;filename=#{LINK_REPORT_CSV_NAME}.csv")

      report.to_csv
    when "html"
      # ameba:disable Lint/UselessAssign
      data = report.call

      render "src/views/report.ecr", "src/views/layouts/layout.ecr"
    else
      env.response.status_code = 200
      env.response.content_type = "application/json"

      report.call.to_json
    end
  end

  post "/" do |env|
    authorized = Auth.authorized?(env.request)
    unless authorized
      halt env, status_code: 401, response: "Not authorized"
    end

    redis = Redis.new(url: REDIS_URL)
    key_available = false
    redirect_url = env.params.body.fetch("redirect_url", nil)

    if redirect_url.nil?
      halt env, status_code: 422, response: "Must provide redirect_url param."
    end

    until key_available
      key = Random.new.hex(3)
      key_available = redis.exists(key) == 0
    end

    redis.mset({
      "#{key}:url"      => redirect_url.strip,
      "#{key}:requests" => 0,
    })

    env.response.status_code = 201
    env.response.content_type = "text/plain; charset=utf-8"
    "#{SHORT_URL}/#{key}"
  end

  get "/:short_code" do |env|
    redis = Redis.new(url: REDIS_URL)
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

  get "/:short_code/inspect.:format" do |env|
    authorized = Auth.authorized?(env.request)
    unless authorized
      halt env, status_code: 401, response: "Not authorized"
    end

    redis = Redis.new(url: REDIS_URL)
    request_key = env.params.url["short_code"].strip
    format = (env.params.url["format"] || "json").to_s.strip.downcase

    data = {
      "short_link"    => "#{SHORT_URL}/#{request_key}",
      "expanded_link" => redis.get("#{request_key}:url"),
      "request_count" => redis.get("#{request_key}:requests").to_s,
      "report_date"   => Time.utc.to_s("%Y-%m-%d %H:%M:%S %:z"),
    }

    case format
    when "csv"
      env.response.status_code = 200
      env.response.content_type = "application/octet-stream; charset=utf-8"
      env.response.headers.add("Content-Disposition", "attachment;filename=shortlink_#{request_key}.csv")

      CSV.build(quoting: CSV::Builder::Quoting::ALL) do |csv|
        csv.row "Short Link", "Expanded Link", "Request Count", "Report Date"
        csv.row data["short_link"], data["expanded_link"], data["request_count"], data["report_date"]
      end
    when "html"
      render "src/views/inspect.ecr", "src/views/layouts/layout.ecr"
    else
      env.response.status_code = 200
      env.response.content_type = "application/json"

      data.to_json
    end
  end

  get "/:short_code/stats" do |env|
    authorized = Auth.authorized?(env.request)
    unless authorized
      halt env, status_code: 401, response: "Not authorized"
    end

    redis = Redis.new(url: REDIS_URL)
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
  Kemal.run(port: PORT)
end
