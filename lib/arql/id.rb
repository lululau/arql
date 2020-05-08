module Arql
  class ID
    @worker_id_bits = 5
    @data_center_id_bits = 5
    @max_worker_id = -1 ^ (-1 << @worker_id_bits)
    @max_data_center_id = -1 ^ (-1 << @data_center_id_bits)

    @sequence_bits = 12
    @worker_id_shift = @sequence_bits
    @data_center_id_shift = @sequence_bits + @worker_id_shift
    @timestamp_left_shift = @sequence_bits + @worker_id_bits + @data_center_id_bits
    @sequence_mask = -1 ^ (-1 << @sequence_bits)

    @id_epoch = (Time.new(2018, 1, 1, 0, 0, 0).to_f * 1000).to_i
    @worker_id = 0
    @data_center_id = 0
    @sequence = 0

    @last_timestamp = -1

    class << self
      def long
        ts = (Time.now.to_f * 1000).to_i
        if ts < @last_timestamp
          raise 'Clock moved backwards.'
        end

        if ts == @last_timestamp
          @sequence = (@sequence + 1) & @sequence_mask
          if (@sequence == 0)
            ts = til_next_millis(@last_timestamp)
          end
        else
          @sequence = 0
        end
        @last_timestamp = ts

        ((ts - @id_epoch) << @timestamp_left_shift) | (@data_center_id << @data_center_id_shift) | (@worker_id << @worker_id_shift) | @sequence
      end

      def uuid
        require 'securerandom'
        SecureRandom.uuid.gsub('-', '')
      end

      private

      def til_next_millis(last_timestamp)
        ts = (Time.now.to_f * 1000).to_i
        while ts <= last_timestamp
          ts = (Time.now.to_f * 1000).to_i
        end
        ts
      end
    end
  end
end

::ID = Arql::ID
