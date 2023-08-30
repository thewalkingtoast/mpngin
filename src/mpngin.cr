require "dotenv"

Dotenv.load

require "json"
require "kemal"

require "./mpngin/constants"
require "./mpngin/version"
require "./mpngin/repository"

REPOSITORY = Mpngin::Repository.new

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

    env.response.status_code = 201
    env.response.content_type = "text/plain; charset=utf-8"

    REPOSITORY.store_application
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
      env.response.content_type = "application/json; charset=utf-8"

      report.call.to_json
    end
  end

  post "/" do |env|
    authorized = Auth.authorized?(env.request)
    unless authorized
      halt env, status_code: 401, response: "Not authorized"
    end

    redirect_url = env.params.body.fetch("redirect_url", nil)
    if redirect_url.nil?
      halt env, status_code: 422, response: "Must provide redirect_url param."
    end

    short_link_data = REPOSITORY.store_short_link(
      from: SHORT_URL, to: redirect_url
    )

    env.response.status_code = 201
    env.response.content_type = "text/plain; charset=utf-8"

    short_link_data["short_link"]
  end

  get "/:short_code" do |env|
    key = env.params.url["short_code"].strip
    data = REPOSITORY.fetch_short_link(key)

    if data.nil?
      halt env, status_code: 404, response: "No short link found."
    end

    REPOSITORY.increment_request_count(key)
    env.redirect data["expanded_link"].as(String)
  end

  get "/:short_code/inspect.:format" do |env|
    authorized = Auth.authorized?(env.request)
    unless authorized
      halt env, status_code: 401, response: "Not authorized"
    end

    format = (env.params.url["format"] || "json").to_s.strip.downcase
    request_key = env.params.url["short_code"].strip

    data = REPOSITORY.fetch_short_link(request_key)

    if data.nil?
      halt env, status_code: 404, response: "No short link found."
    end

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

    key = env.params.url["short_code"].to_s.strip
    data = REPOSITORY.fetch_short_link(key)

    env.response.content_type = "text/plain; charset=utf-8"

    if data.nil?
      halt env, status_code: 404, response: "No short link found."
    end

    data["request_count"]
  end

  serve_static false
  Kemal.run(port: PORT)
end
