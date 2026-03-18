# frozen_string_literal: true

module Legion
  module Extensions
    module WorkingMemory
      module Helpers
        class Buffer
          attr_reader :items

          def initialize
            @items = []
          end

          def store(content:, buffer_type: :episodic, priority: :normal, tags: [])
            return nil unless Constants::BUFFER_TYPES.include?(buffer_type)
            return nil unless Constants::PRIORITY_LEVELS.key?(priority)

            item = BufferItem.new(content: content, buffer_type: buffer_type, priority: priority, tags: tags)
            @items << item
            evict_if_over_capacity
            item
          end

          def retrieve(id)
            @items.find { |i| i.id == id }
          end

          def retrieve_by_tag(tag)
            @items.select { |i| i.tags.include?(tag) }
          end

          def retrieve_by_type(buffer_type)
            @items.select { |i| i.buffer_type == buffer_type }
          end

          def rehearse(id)
            item = retrieve(id)
            return nil unless item

            item.rehearse
            item
          end

          def remove(id)
            @items.reject! { |i| i.id == id }
          end

          def tick_decay
            @items.each(&:decay)
            @items.reject!(&:expired?)
          end

          def consolidation_candidates
            @items.select(&:consolidation_ready?)
          end

          def current_load
            return 0.0 if capacity.zero?

            (@items.size.to_f / capacity).clamp(0.0, 1.0)
          end

          def load_level
            load = current_load
            Constants::LOAD_LEVELS.each do |level, threshold|
              return level if load >= threshold
            end
            :idle
          end

          def capacity
            Constants::CAPACITY + chunk_bonus
          end

          def available_slots
            [capacity - @items.size, 0].max
          end

          def full?
            @items.size >= capacity
          end

          def clear
            @items.clear
          end

          def size
            @items.size
          end

          def to_h
            {
              size:       @items.size,
              capacity:   capacity,
              load:       current_load.round(4),
              load_level: load_level,
              by_type:    items_by_type,
              available:  available_slots
            }
          end

          private

          def chunk_bonus
            chunked = @items.group_by { |i| i.tags.first }.count { |_, group| group.size > 1 }
            [chunked, Constants::CHUNK_BONUS].min
          end

          def evict_if_over_capacity
            return unless @items.size > capacity

            @items.sort_by!(&:activation)
            @items.shift(@items.size - capacity)
          end

          def items_by_type
            Constants::BUFFER_TYPES.to_h { |t| [t, @items.count { |i| i.buffer_type == t }] }
          end
        end
      end
    end
  end
end
