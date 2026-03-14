# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::WorkingMemory::Client do
  subject(:client) { described_class.new }

  describe '#initialize' do
    it 'creates a default buffer' do
      expect(client.buffer).to be_a(Legion::Extensions::WorkingMemory::Helpers::Buffer)
    end

    it 'accepts an injected buffer' do
      custom = Legion::Extensions::WorkingMemory::Helpers::Buffer.new
      injected = described_class.new(buffer: custom)
      expect(injected.buffer).to equal(custom)
    end
  end

  describe 'full workflow integration' do
    it 'stores, retrieves, rehearses, and decays items through the cognitive cycle' do
      # Store items across buffer types
      verbal = client.store_item(content: 'spoken word', buffer_type: :verbal, priority: :normal, tags: [:conversation])
      spatial = client.store_item(content: 'map layout', buffer_type: :spatial, priority: :high, tags: [:navigation])
      episodic = client.store_item(content: 'meeting memory', buffer_type: :episodic, priority: :critical, tags: [:work])

      expect(verbal[:success]).to be true
      expect(spatial[:success]).to be true
      expect(episodic[:success]).to be true

      # Check status
      status = client.buffer_status
      expect(status[:status][:size]).to eq(3)

      # Retrieve by type
      verbal_items = client.retrieve_by_type(buffer_type: :verbal)
      expect(verbal_items[:count]).to eq(1)

      # Retrieve by tag
      work_items = client.retrieve_by_tag(tag: :work)
      expect(work_items[:count]).to eq(1)

      # Rehearse the verbal item to prevent decay
      rehearsed = client.rehearse_item(id: verbal[:item][:id])
      expect(rehearsed[:item][:rehearsal_count]).to eq(1)

      # Run a tick (decay cycle)
      tick_result = client.update_working_memory
      expect(tick_result[:success]).to be true

      # Critical item should be a consolidation candidate
      candidates = client.consolidation_candidates
      expect(candidates[:count]).to be >= 1

      # Find interference between same-type same-tag items
      client.store_item(content: 'another conversation', buffer_type: :verbal, priority: :normal, tags: [:conversation])
      interference = client.find_interference(id: verbal[:item][:id])
      expect(interference[:count]).to be >= 1

      # Stats reflect the current state
      stats = client.working_memory_stats
      expect(stats[:size]).to eq(4)
      expect(stats[:load]).to be > 0.0

      # Remove an item
      client.remove_item(id: spatial[:item][:id])
      expect(client.working_memory_stats[:size]).to eq(3)

      # Clear everything
      client.clear_buffer
      expect(client.working_memory_stats[:size]).to eq(0)
    end

    it 'models the 7 plus-or-minus 2 capacity limit' do
      # Fill to base capacity
      7.times { |i| client.store_item(content: "item #{i}", priority: :normal) }
      expect(client.buffer.size).to eq(7)

      # Without chunking, adding more evicts lowest activation
      3.times { |i| client.store_item(content: "overflow #{i}", priority: :high) }
      expect(client.buffer.size).to be <= client.buffer.capacity
    end

    it 'demonstrates chunking bonus' do
      # Add items with shared tags to trigger chunking
      3.times { |i| client.store_item(content: "group_a_#{i}", tags: [:group_a]) }
      3.times { |i| client.store_item(content: "group_b_#{i}", tags: [:group_b]) }

      # Capacity should exceed base due to chunking
      expect(client.buffer.capacity).to be > Legion::Extensions::WorkingMemory::Helpers::Constants::CAPACITY
    end
  end
end
