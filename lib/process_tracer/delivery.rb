require 'rest_client'

module ProcessTracer
  class Delivery
    def self.push(started_at, pieces)
      pieces.each_with_index do |piece, index|
        next_piece = pieces[index + 1]
        next unless next_piece && next_piece[:depth] > piece[:depth]

        piece[:child_pieces] = pieces[(index + 2)..].select do |later_piece|
          if next_piece[:depth] == later_piece[:depth]
            later_piece
          else
            break
          end
        end
      end

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