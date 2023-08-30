require "./spec_helper"
require "timecop"

Timecop.safe_mode = true

describe "Mpngin" do
  it "redirects to ENV['FALLBACK_URL']" do
    # Make the request
    get "/"

    # Assert the response redirects
    response.status_code.should eq(302)
    response.headers["location"].should eq(ENV["FALLBACK_URL"])
  end

  it "responds to a basic health check" do
    # Make the request
    get "/health_check"

    response.status_code.should eq(200)
    response.content_type.should eq("text/plain")
    response.body.should eq("I am a-okay.")
  end

  describe "making a new downstream application" do
    context "with valid secret authorization" do
      it "generates and registers an application key" do
        # Make sure no app keys exist in Redis
        redis.keys("*:application").size.should eq(1)

        # Setup request headers
        headers = HTTP::Headers.new
        headers["Authorization"] = "bearer #{ENV["SECRET_TOKEN"]}"
        headers["Accept"] = "text/plain"

        # Make the request
        post("/application", headers: headers)

        # Assert the response is okay
        response.status_code.should eq(201)
        response.content_type.should eq("text/plain")

        # Assert a key was made with the returned app key
        redis.keys("*:application").size.should eq(2)
        redis.get("#{response.body}:application").should eq("1")
      end
    end

    context "without valid authorization" do
      it "renders 401 not authorized" do
        # Make sure no app keys exist in Redis
        redis.keys("*:application").size.should eq(1)

        # Setup request headers
        headers = HTTP::Headers.new
        headers["Accept"] = "text/plain"

        # Make the request
        post("/application", headers: headers)

        # Assert the response is a not authorized response
        response.status_code.should eq(401)
        response.body.should eq("Not authorized")

        # Assert no app key was made
        redis.keys("*:application").size.should eq(1)
      end
    end
  end

  describe "generating a link report" do
    context "as HTML" do
      context "without valid authorization" do
        it "renders 401 not authorized" do
          # Setup request headers
          headers = HTTP::Headers.new
          headers["Accept"] = "text/html"

          # Make the request
          get("/report.html", headers: headers)

          # Assert the response is a not authorized response
          response.status_code.should eq(401)
          response.body.should eq("Not authorized")
        end
      end

      context "with valid authorization" do
        it "renders an HTML report page" do
          # Ensure the short code exists in Redis
          short_code = "abc123"
          final_url = "https://foobarbatz.com"
          request_count = 0
          redis.set("#{short_code}:url", final_url)
          redis.set("#{short_code}:requests", request_count)

          # Setup request headers
          headers = HTTP::Headers.new
          headers["Accept"] = "text/html"
          headers["Authorization"] = "bearer #{ENV["SECRET_TOKEN"]}"

          # Make the request
          get("/report.html", headers: headers)

          response.status_code.should eq(200)
          response.content_type.should eq("text/html")

          response_body = response.body.strip
          response_body.should contain("<!doctype html>")
          response_body.should contain(host.to_s)
          response_body.should contain(short_code.to_s)
          response_body.should contain(final_url.to_s)
          response_body.should contain(request_count.to_s)
        end
      end
    end

    context "as CSV" do
      context "without valid authorization" do
        it "renders 401 not authorized" do
          # Setup request headers
          headers = HTTP::Headers.new
          headers["Accept"] = "text/html"

          # Make the request
          get("/report.html", headers: headers)

          # Assert the response is a not authorized response
          response.status_code.should eq(401)
          response.body.should eq("Not authorized")
        end
      end

      context "with valid authorization" do
        it "renders a CSV for download" do
          # Ensure the short code exists in Redis
          short_code = "abc123"
          final_url = "https://foobarbatz.com"
          request_count = 0
          redis.set("#{short_code}:url", final_url)
          redis.set("#{short_code}:requests", request_count)

          # Setup request headers
          headers = HTTP::Headers.new
          headers["Accept"] = "text/csv"
          headers["Authorization"] = "bearer #{ENV["SECRET_TOKEN"]}"

          # Make the request
          get("/report.csv", headers: headers)

          response.status_code.should eq(200)
          response.content_type.should eq("application/octet-stream")
          response.headers["Content-Disposition"].should eq("attachment;filename=#{csv_report_name}.csv")
        end
      end
    end

    context "as JSON" do
      context "without valid authorization" do
        it "renders 401 not authorized" do
          # Setup request headers
          headers = HTTP::Headers.new
          headers["Accept"] = "text/html"

          # Make the request
          get("/report.html", headers: headers)

          # Assert the response is a not authorized response
          response.status_code.should eq(401)
          response.body.should eq("Not authorized")
        end
      end

      context "with valid authorization" do
        it "renders a JSON payload" do
          # Ensure the short code exists in Redis
          short_code = "abc123"
          final_url = "https://foobarbatz.com"
          request_count = 0

          redis.set("#{short_code}:url", final_url)
          redis.set("#{short_code}:requests", request_count)

          # Setup request headers
          headers = HTTP::Headers.new
          headers["Accept"] = "application/json"
          headers["Authorization"] = "bearer #{ENV["SECRET_TOKEN"]}"

          # Make the request
          get("/report.json", headers: headers)

          response.status_code.should eq(200)
          response.content_type.should eq("application/json")
          response.body.should eq(
            [{
              "short_link":    "#{host}/#{short_code}",
              "expanded_link": final_url,
              "request_count": request_count.to_s,
            }].to_json
          )
        end
      end
    end
  end

  describe "making a new shortened URL request" do
    context "without valid authorization" do
      it "renders 401 not authorized" do
        # Setup request headers
        headers = HTTP::Headers.new
        headers["Accept"] = "text/plain"

        # Make the request
        post("/", headers: headers, body: "redirect_url=https%3A%2F%2Ffoobarbatz.com")

        # Assert the response is a not authorized response
        response.status_code.should eq(401)
        response.body.should eq("Not authorized")

        # Assert no request key was made
        redis.keys("*:url").size.should eq(0)
        redis.keys("*:requests").size.should eq(0)
      end
    end

    context "with valid authorization" do
      context "without a redirect URL" do
        it "renders 422 unprocessable entity" do
          # Setup request headers
          headers = HTTP::Headers.new
          headers["Accept"] = "text/plain"
          headers["Authorization"] = test_app_authorization

          # Make the request
          post("/", headers: headers)

          # Assert the response is an unprocessable entity response
          response.status_code.should eq(422)
          response.body.should eq("Must provide redirect_url param.")

          # Assert no request key was made
          redis.keys("*:url").size.should eq(0)
          redis.keys("*:requests").size.should eq(0)
        end
      end

      context "with a redirect url" do
        it "makes a short code that redirects" do
          # Setup request headers
          headers = HTTP::Headers.new
          headers["Accept"] = "text/plain; charset=utf-8"
          headers["Authorization"] = test_app_authorization
          headers["Content-Type"] = "application/x-www-form-urlencoded"

          # Make the request
          post("/", headers: headers, body: "redirect_url=https%3A%2F%2Ffoobarbatz.com")

          # Assert the response is okay
          response.status_code.should eq(201)
          response.content_type.should eq("text/plain")

          # Assert response body is a URL.
          matching = /http(s?)\:\/\/(.+).(.+)\/(.+){6}/i =~ response.body
          matching.should eq(0)

          # Grab short code off of response body.
          short_code = response.body.split("/").pop
          namespace = "#{hostname}:#{short_code}"

          # Assert a key was made with the returned app key
          redis.get("#{namespace}:url").should eq("https://foobarbatz.com")
          redis.get("#{namespace}:requests").should eq("0")
        end

        context "with a custom short url" do
          it "makes a short code that redirects" do
            # Setup request headers
            headers = HTTP::Headers.new
            headers["Accept"] = "text/plain; charset=utf-8"
            headers["Authorization"] = test_app_authorization
            headers["Content-Type"] = "application/x-www-form-urlencoded"

            # Make the request
            params = URI::Params.build do |form|
              form.add "redirect_url", "https://foobarbatz.com"
              form.add "short_url", "https://thehorde.org"
            end

            post("/", headers: headers, body: params)

            # Assert the response is okay
            response.status_code.should eq(201)
            response.content_type.should eq("text/plain")

            # Assert response body is a URL.
            matching = /http(s?)\:\/\/(.+).(.+)\/(.+){6}/i =~ response.body
            matching.should eq(0)

            # Grab short code off of response body.
            short_code = response.body.split("/").pop
            namespace = "thehorde.org:#{short_code}"

            # Assert a key was made with the returned app key
            redis.get("#{namespace}:url").should eq("https://foobarbatz.com")
            redis.get("#{namespace}:requests").should eq("0")
          end
        end
      end
    end
  end

  describe "loading a shortened URL" do
    it "redirects on found short code" do
      # Ensure the short code exists in Redis
      short_code = "abc123"
      final_url = "https://foobarbatz.com"
      namespace = "#{hostname}:#{short_code}"

      redis.set("#{namespace}:url", final_url)
      redis.set("#{namespace}:requests", 0)

      get "/#{short_code}"

      # Assert the response redirects
      response.status_code.should eq(302)
      response.headers["location"].should eq(final_url)
    end

    it "increments the request count on found short code" do
      # Ensure the short code exists in Redis
      short_code = "abc123"
      final_url = "https://foobarbatz.com"
      namespace = "#{hostname}:#{short_code}"

      redis.set("#{namespace}:url", final_url)
      redis.set("#{namespace}:requests", 0)

      redis.get("#{namespace}:requests").should eq("0")

      3.times do |i|
        # Make request
        get "/#{short_code}"

        # Assert the response redirects
        response.status_code.should eq(302)
        response.headers["location"].should eq(final_url)

        # Assert request count is incremented
        count = i + 1
        redis.get("#{namespace}:requests").should eq(count.to_s)
      end
    end

    it "renders 404 on missing short code" do
      # Ensure the short code does not exist in Redis
      short_code = "abc123"
      namespace = "#{hostname}:#{short_code}"

      redis.del("#{namespace}:url")
      redis.del("#{namespace}:requests")

      # Make request
      get "/#{short_code}"

      # Assert the response redirects
      response.status_code.should eq(404)
      response.content_type.should eq("text/html")
      response.body.should eq("No short link found.")
    end
  end

  describe "loading a shortened URL's stats" do
    context "without valid authorization" do
      it "renders 401 not authorized" do
        # Ensure the short code exists in Redis
        short_code = "abc123"
        final_url = "https://foobarbatz.com"
        namespace = "#{hostname}:#{short_code}"

        redis.set("#{namespace}:url", final_url)
        redis.set("#{namespace}:requests", 0)

        # Make request
        get "/#{short_code}/stats"

        # Assert the response is a not authorized response
        response.status_code.should eq(401)
        response.body.should eq("Not authorized")
      end
    end

    context "with valid authorization" do
      it "renders the number of requests for a found short code" do
        # Ensure the short code exists in Redis
        short_code = "abc123"
        final_url = "https://foobarbatz.com"
        namespace = "#{hostname}:#{short_code}"

        redis.set("#{namespace}:url", final_url)
        redis.set("#{namespace}:requests", 1337)

        # Setup request headers
        headers = HTTP::Headers.new
        headers["Accept"] = "text/plain"
        headers["Authorization"] = test_app_authorization

        # Make request
        get("/#{short_code}/stats", headers: headers)

        # Assert the response is valid
        response.status_code.should eq(200)
        response.content_type.should eq("text/plain")
        response.body.should eq("1337")
      end

      it "renders unknown text on missing short code" do
        # Ensure the short code exists in Redis
        short_code = "abc123"
        namespace = "#{hostname}:#{short_code}"

        redis.del("#{namespace}:url")
        redis.del("#{namespace}:requests")

        # Setup request headers
        headers = HTTP::Headers.new
        headers["Accept"] = "text/plain"
        headers["Authorization"] = test_app_authorization

        # Make request
        get("/#{short_code}/stats", headers: headers)

        # Assert the response redirects
        response.status_code.should eq(404)
        response.content_type.should eq("text/plain")
        response.body.should eq("No short link found.")
      end
    end
  end

  describe "inspecting a shortened URL" do
    context "without valid authorization" do
      ["HTML", "JSON", "CSV"].each do |format|
        context "as #{format}" do
          it "renders 401 not authorized" do
            # Ensure the short code exists in Redis
            short_code = "abc123"
            final_url = "https://foobarbatz.com"
            namespace = "#{hostname}:#{short_code}"

            redis.set("#{namespace}:url", final_url)
            redis.set("#{namespace}:requests", 0)

            # Make request
            get "/#{short_code}/inspect.#{format.downcase}"

            # Assert the response is a not authorized response
            response.status_code.should eq(401)
            response.body.should eq("Not authorized")
          end
        end
      end
    end

    context "with valid authorization" do
      context "as HTML" do
        it "renders short link details" do
          # Ensure the short code exists in Redis
          short_code = "abc123"
          final_url = "https://foobarbatz.com"
          namespace = "#{hostname}:#{short_code}"
          request_count = 1337

          redis.set("#{namespace}:url", final_url)
          redis.set("#{namespace}:requests", request_count)

          # Setup request headers
          headers = HTTP::Headers.new
          headers["Accept"] = "text/html"
          headers["Authorization"] = test_app_authorization

          # Make request
          get("/#{short_code}/inspect.html", headers: headers)

          # Assert the response is valid
          response.status_code.should eq(200)
          response.content_type.should eq("text/html")

          response_body = response.body.strip
          response_body.should contain("<!doctype html>")
          response_body.should contain(short_code.to_s)
          response_body.should contain(final_url.to_s)
          response_body.should contain(request_count.to_s)
        end
      end

      context "as CSV" do
        it "renders short link details" do
          # Ensure the short code exists in Redis
          short_code = "abc123"
          final_url = "https://foobarbatz.com"
          namespace = "#{hostname}:#{short_code}"

          redis.set("#{namespace}:url", final_url)
          redis.set("#{namespace}:requests", 1337)

          csv_report_name = "shortlink_#{short_code}"

          # Setup request headers
          headers = HTTP::Headers.new
          headers["Accept"] = "text/csv"
          headers["Authorization"] = test_app_authorization

          # Make request
          get("/#{short_code}/inspect.csv", headers: headers)

          # Assert the response is valid
          response.content_type.should eq("application/octet-stream")
          response.headers["Content-Disposition"].should eq("attachment;filename=#{csv_report_name}.csv")
        end
      end

      context "as JSON" do
        it "renders short link details" do
          # Ensure the short code exists in Redis
          short_code = "abc123"
          final_url = "https://foobarbatz.com"
          namespace = "#{hostname}:#{short_code}"
          request_count = 1337

          redis.set("#{namespace}:url", final_url)
          redis.set("#{namespace}:requests", request_count)

          # Setup request headers
          headers = HTTP::Headers.new
          headers["Accept"] = "application/json"
          headers["Authorization"] = test_app_authorization

          time = Time.utc
          Timecop.freeze(time) do
            # Make request
            get("/#{short_code}/inspect.json", headers: headers)

            # Assert the response is valid
            response.status_code.should eq(200)
            response.content_type.should eq("application/json")

            response_body = response.body.strip
            response_body.should eq(
              {
                "expanded_link": final_url,
                "report_date":   time.to_s("%Y-%m-%d %H:%M:%S %:z"),
                "request_count": request_count.to_s,
                "short_code":    short_code,
                "short_link":    "https://#{hostname}/#{short_code}",
              }.to_json
            )
          end
        end
      end
    end
  end
end
