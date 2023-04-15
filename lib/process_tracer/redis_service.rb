class ProcessTracer::RedisService
  class << self
    def get_json(key)
      JSON.parse(connection.get(key))
    end

    def append_pair(key, value)
      key_count = connection.scan(
        0, match: "#{key}:*"
      ).last.count

      Rails.logger.info(value)

      connection.append(
        "#{key}:#{key_count}",
        value.to_json
      )
    end

    def fetch_all
      connection.keys.map do |key|
        get_json(key)
      end
    end

    def flush_db!
      connection.flushdb
    end

    def connection
      @connection ||= Redis.new(db: ENV.fetch('TRACER_REDIS_NUMBER', 8))
    end
  end
end
