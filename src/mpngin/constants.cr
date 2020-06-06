module Mpngin
  FALLBACK_URL         = ENV["FALLBACK_URL"].to_s
  REDIS_DB             = ENV["REDIS_DATABASE"].to_i
  SECRET_TOKEN         = ENV["SECRET_TOKEN"].to_s
  SHORT_URL            = ENV["SHORT_URL"].to_s
  PORT                 = ENV.fetch("PORT", "3000").to_i
end
