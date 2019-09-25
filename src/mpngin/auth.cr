module Mpngin
  module Auth
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
end
