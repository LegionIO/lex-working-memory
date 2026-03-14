# frozen_string_literal: true

module Legion
  module Extensions
    module WorkingMemory
      module Runners
        module WorkingMemory
          include Legion::Extensions::Helpers::Lex

          def buffer
            @buffer ||= Helpers::Buffer.new
          end

          def update_working_memory(**)
            buffer.tick_decay
            candidates = buffer.consolidation_candidates
            Legion::Logging.debug "[working_memory] tick: size=#{buffer.size} load=#{buffer.load_level} candidates=#{candidates.size}"
            { success: true, status: buffer.to_h, consolidation_candidates: candidates.map(&:to_h) }
          end

          def store_item(content:, buffer_type: :episodic, priority: :normal, tags: [], **)
            Legion::Logging.debug '[working_memory] buffer full, eviction will occur' if buffer.full?

            item = buffer.store(content: content, buffer_type: buffer_type, priority: priority, tags: tags)
            Legion::Logging.debug "[working_memory] stored item=#{item.id} type=#{buffer_type} priority=#{priority}"
            { success: true, item: item.to_h }
          end

          def retrieve_item(id:, **)
            item = buffer.retrieve(id)
            return { success: false, reason: :not_found } unless item

            { success: true, item: item.to_h }
          end

          def rehearse_item(id:, **)
            item = buffer.rehearse(id)
            return { success: false, reason: :not_found } unless item

            Legion::Logging.debug "[working_memory] rehearsed item=#{id} activation=#{item.activation.round(4)}"
            { success: true, item: item.to_h }
          end

          def retrieve_by_tag(tag:, **)
            items = buffer.retrieve_by_tag(tag)
            { success: true, items: items.map(&:to_h), count: items.size }
          end

          def retrieve_by_type(buffer_type:, **)
            items = buffer.retrieve_by_type(buffer_type)
            { success: true, items: items.map(&:to_h), count: items.size }
          end

          def remove_item(id:, **)
            buffer.remove(id)
            Legion::Logging.debug "[working_memory] removed item=#{id}"
            { success: true }
          end

          def buffer_status(**)
            { success: true, status: buffer.to_h }
          end

          def consolidation_candidates(**)
            candidates = buffer.consolidation_candidates
            { success: true, candidates: candidates.map(&:to_h), count: candidates.size }
          end

          def working_memory_stats(**)
            {
              success:    true,
              size:       buffer.size,
              capacity:   buffer.capacity,
              load:       buffer.current_load.round(4),
              load_level: buffer.load_level,
              full:       buffer.full?,
              available:  buffer.available_slots
            }
          end

          def clear_buffer(**)
            buffer.clear
            Legion::Logging.debug '[working_memory] buffer cleared'
            { success: true }
          end

          def find_interference(id:, **)
            item = buffer.retrieve(id)
            return { success: false, reason: :not_found } unless item

            interfering = buffer.items.select { |other| other.id != id && item.interferes_with?(other) }
            { success: true, item_id: id, interfering: interfering.map(&:to_h), count: interfering.size }
          end
        end
      end
    end
  end
end
