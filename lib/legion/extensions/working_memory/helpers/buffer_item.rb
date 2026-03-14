# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module WorkingMemory
      module Helpers
        class BufferItem
          attr_reader :id, :content, :buffer_type, :priority, :tags, :created_at
          attr_accessor :activation, :rehearsal_count, :age_ticks

          def initialize(content:, buffer_type: :episodic, priority: :normal, tags: [])
            @id              = SecureRandom.uuid
            @content         = content
            @buffer_type     = buffer_type
            @priority        = priority
            @tags            = tags
            @activation      = Constants::PRIORITY_LEVELS[priority] || 0.5
            @rehearsal_count = 0
            @age_ticks       = 0
            @created_at      = Time.now.utc
          end

          def rehearse
            @rehearsal_count += 1
            @activation = [@activation + Constants::REHEARSAL_BOOST, 1.0].min
            @age_ticks = 0
          end

          def decay
            @age_ticks += 1
            @activation = [@activation - Constants::DECAY_RATE, 0.0].max
          end

          def expired?
            @age_ticks >= Constants::MAX_AGE_TICKS || @activation <= 0.0
          end

          def consolidation_ready?
            @activation >= Constants::CONSOLIDATION_THRESHOLD
          end

          def interferes_with?(other)
            return false unless other.is_a?(BufferItem)
            return false if @buffer_type != other.buffer_type

            @tags.any? { |t| other.tags.include?(t) } && (@activation - other.activation).abs < Constants::INTERFERENCE_THRESHOLD
          end

          def to_h
            {
              id:                  @id,
              content:             @content,
              buffer_type:         @buffer_type,
              priority:            @priority,
              activation:          @activation.round(4),
              rehearsal_count:     @rehearsal_count,
              age_ticks:           @age_ticks,
              expired:             expired?,
              consolidation_ready: consolidation_ready?
            }
          end
        end
      end
    end
  end
end
