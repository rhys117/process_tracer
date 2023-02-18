require 'rest_client'

module ProcessTracer
  class Delivery
    def self.push(piece)
      RestClient.post(
        'localhost:3000/traces',
        {
          trace: piece
        }
      )
    end
  end
end
