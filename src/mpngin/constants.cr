module Mpngin
  FALLBACK_URL         = ENV["FALLBACK_URL"].to_s
  LINK_REPORT_CSV_NAME = ENV.fetch("LINK_REPORT_CSV_NAME", "MPNGIN_Link_Report")
  PORT                 = ENV.fetch("PORT", "7001").to_i
  REDIS_URL            = ENV["REDIS_URL"].to_s
  SECRET_TOKEN         = ENV["SECRET_TOKEN"].to_s
  SHORT_ID_SIZE        = ENV.fetch("SHORT_ID_SIZE", "3").to_i # In bytes. See Random::Secure#hex
  SHORT_URL            = ENV["SHORT_URL"].to_s
end
