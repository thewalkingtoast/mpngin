module Mpngin
  FALLBACK_URL         = ENV["FALLBACK_URL"].to_s
  REDIS_URL            = ENV["REDIS_URL"].to_s
  SECRET_TOKEN         = ENV["SECRET_TOKEN"].to_s
  SHORT_URL            = ENV["SHORT_URL"].to_s
  PORT                 = ENV.fetch("PORT", "7001").to_i
  LINK_REPORT_CSV_NAME = ENV.fetch("LINK_REPORT_CSV_NAME", "MPNGIN_Link_Report")
end
