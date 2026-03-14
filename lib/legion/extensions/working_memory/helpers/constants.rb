# frozen_string_literal: true

module Legion
  module Extensions
    module WorkingMemory
      module Helpers
        module Constants
          CAPACITY = 7

          CHUNK_BONUS = 3

          BUFFER_TYPES = %i[verbal spatial episodic].freeze

          DECAY_RATE = 0.15

          REHEARSAL_BOOST = 0.3

          PRIORITY_LEVELS = {
            critical:   1.0,
            high:       0.75,
            normal:     0.5,
            low:        0.25,
            background: 0.1
          }.freeze

          MAX_AGE_TICKS = 30

          INTERFERENCE_THRESHOLD = 0.7

          CONSOLIDATION_THRESHOLD = 0.8

          LOAD_LEVELS = {
            overloaded: 1.0,
            high:       0.75,
            moderate:   0.5,
            low:        0.25,
            idle:       0.0
          }.freeze
        end
      end
    end
  end
end
