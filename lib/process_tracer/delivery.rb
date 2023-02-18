require 'rest_client'

module ProcessTracer
  class Delivery
    def self.push(started_at, pieces)
      RestClient.post(
        'localhost:3000/traces',
        {
          started_at: started_at,
          trace: pieces
        }
      )
    end
  end
end