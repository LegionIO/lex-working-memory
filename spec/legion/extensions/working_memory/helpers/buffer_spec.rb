# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::WorkingMemory::Helpers::Buffer do
  subject(:buffer) { described_class.new }

  let(:constants) { Legion::Extensions::WorkingMemory::Helpers::Constants }

  describe '#initialize' do
    it 'starts empty' do
      expect(buffer.items).to eq([])
      expect(buffer.size).to eq(0)
    end
  end

  describe '#store' do
    it 'stores an item and returns it' do
      item = buffer.store(content: 'hello')
      expect(item).to be_a(Legion::Extensions::WorkingMemory::Helpers::BufferItem)
      expect(buffer.size).to eq(1)
    end

    it 'stores with custom buffer_type and priority' do
      item = buffer.store(content: 'spatial data', buffer_type: :spatial, priority: :high)
      expect(item.buffer_type).to eq(:spatial)
      expect(item.priority).to eq(:high)
    end

    it 'stores with tags' do
      item = buffer.store(content: 'tagged', tags: %i[important work])
      expect(item.tags).to eq(%i[important work])
    end

    it 'rejects invalid buffer_type' do
      result = buffer.store(content: 'bad type', buffer_type: :tactile)
      expect(result).to be_nil
      expect(buffer.size).to eq(0)
    end

    it 'rejects invalid priority' do
      result = buffer.store(content: 'bad priority', priority: :urgent)
      expect(result).to be_nil
      expect(buffer.size).to eq(0)
    end

    it 'accepts all valid buffer types' do
      constants::BUFFER_TYPES.each do |type|
        item = buffer.store(content: "test #{type}", buffer_type: type)
        expect(item).not_to be_nil
      end
    end

    it 'accepts all valid priority levels' do
      constants::PRIORITY_LEVELS.each_key do |priority|
        item = buffer.store(content: "test #{priority}", priority: priority)
        expect(item).not_to be_nil
      end
    end

    it 'evicts lowest-activation items when over capacity' do
      (constants::CAPACITY + constants::CHUNK_BONUS + 2).times do |i|
        buffer.store(content: "item #{i}", priority: :normal)
      end
      expect(buffer.size).to be <= buffer.capacity
    end
  end

  describe '#retrieve' do
    it 'finds an item by id' do
      item = buffer.store(content: 'findme')
      found = buffer.retrieve(item.id)
      expect(found).to eq(item)
    end

    it 'returns nil for unknown id' do
      expect(buffer.retrieve('nonexistent')).to be_nil
    end
  end

  describe '#retrieve_by_tag' do
    it 'returns items matching the tag' do
      buffer.store(content: 'a', tags: [:work])
      buffer.store(content: 'b', tags: [:play])
      buffer.store(content: 'c', tags: %i[work play])

      work_items = buffer.retrieve_by_tag(:work)
      expect(work_items.size).to eq(2)
      expect(work_items.map(&:content)).to contain_exactly('a', 'c')
    end

    it 'returns empty array for unmatched tag' do
      buffer.store(content: 'a', tags: [:work])
      expect(buffer.retrieve_by_tag(:missing)).to eq([])
    end
  end

  describe '#retrieve_by_type' do
    it 'returns items of the specified buffer type' do
      buffer.store(content: 'v1', buffer_type: :verbal)
      buffer.store(content: 's1', buffer_type: :spatial)
      buffer.store(content: 'v2', buffer_type: :verbal)

      verbal = buffer.retrieve_by_type(:verbal)
      expect(verbal.size).to eq(2)
      expect(verbal.map(&:content)).to contain_exactly('v1', 'v2')
    end
  end

  describe '#rehearse' do
    it 'rehearses an existing item' do
      item = buffer.store(content: 'rehearse me')
      initial_activation = item.activation
      result = buffer.rehearse(item.id)
      expect(result.activation).to be > initial_activation
      expect(result.rehearsal_count).to eq(1)
    end

    it 'returns nil for unknown id' do
      expect(buffer.rehearse('nonexistent')).to be_nil
    end
  end

  describe '#remove' do
    it 'removes an item by id' do
      item = buffer.store(content: 'remove me')
      buffer.remove(item.id)
      expect(buffer.size).to eq(0)
      expect(buffer.retrieve(item.id)).to be_nil
    end
  end

  describe '#tick_decay' do
    it 'decays all items' do
      item = buffer.store(content: 'decaying', priority: :normal)
      initial = item.activation
      buffer.tick_decay
      expect(item.activation).to be < initial
    end

    it 'removes expired items' do
      item = buffer.store(content: 'expiring', priority: :background)
      constants::MAX_AGE_TICKS.times { buffer.tick_decay }
      expect(buffer.retrieve(item.id)).to be_nil
    end
  end

  describe '#consolidation_candidates' do
    it 'returns items above consolidation threshold' do
      buffer.store(content: 'critical', priority: :critical)
      buffer.store(content: 'normal', priority: :normal)
      candidates = buffer.consolidation_candidates
      expect(candidates.size).to eq(1)
      expect(candidates.first.content).to eq('critical')
    end
  end

  describe '#current_load' do
    it 'returns 0.0 when empty' do
      expect(buffer.current_load).to eq(0.0)
    end

    it 'increases as items are added' do
      3.times { |i| buffer.store(content: "item #{i}") }
      expect(buffer.current_load).to be > 0.0
    end

    it 'clamps at 1.0' do
      20.times { |i| buffer.store(content: "item #{i}", priority: :critical) }
      expect(buffer.current_load).to be <= 1.0
    end
  end

  describe '#load_level' do
    it 'returns :idle when empty' do
      expect(buffer.load_level).to eq(:idle)
    end

    it 'returns higher levels as buffer fills' do
      # Use unique tags to prevent chunk_bonus inflation
      20.times { |i| buffer.store(content: "item #{i}", priority: :critical, tags: [:"unique_#{i}"]) }
      expect(buffer.load_level).to eq(:overloaded)
    end
  end

  describe '#capacity' do
    it 'is at least the base CAPACITY' do
      expect(buffer.capacity).to be >= constants::CAPACITY
    end

    it 'increases with chunking (items sharing tags)' do
      buffer.store(content: 'a1', tags: [:group_a])
      buffer.store(content: 'a2', tags: [:group_a])
      buffer.store(content: 'b1', tags: [:group_b])
      buffer.store(content: 'b2', tags: [:group_b])
      expect(buffer.capacity).to be > constants::CAPACITY
    end

    it 'caps chunk bonus at CHUNK_BONUS' do
      10.times { |i| buffer.store(content: "item #{i}", tags: [:"group_#{i / 2}"]) }
      expect(buffer.capacity).to be <= constants::CAPACITY + constants::CHUNK_BONUS
    end
  end

  describe '#available_slots' do
    it 'equals capacity when empty' do
      expect(buffer.available_slots).to eq(buffer.capacity)
    end

    it 'decreases as items are added' do
      buffer.store(content: 'one')
      expect(buffer.available_slots).to eq(buffer.capacity - 1)
    end

    it 'never goes below zero' do
      20.times { |i| buffer.store(content: "item #{i}", priority: :critical) }
      expect(buffer.available_slots).to be >= 0
    end
  end

  describe '#full?' do
    it 'is false when empty' do
      expect(buffer.full?).to be false
    end

    it 'is true at capacity' do
      # Use unique tags to prevent chunk_bonus inflation (nil first-tag groups all items)
      20.times { |i| buffer.store(content: "item #{i}", priority: :critical, tags: [:"unique_#{i}"]) }
      expect(buffer.full?).to be true
    end
  end

  describe '#clear' do
    it 'removes all items' do
      3.times { |i| buffer.store(content: "item #{i}") }
      buffer.clear
      expect(buffer.size).to eq(0)
    end
  end

  describe '#to_h' do
    it 'returns a status hash' do
      buffer.store(content: 'test')
      h = buffer.to_h
      expect(h).to include(:size, :capacity, :load, :load_level, :by_type, :available)
      expect(h[:size]).to eq(1)
    end

    it 'breaks down items by type' do
      buffer.store(content: 'v', buffer_type: :verbal)
      buffer.store(content: 's', buffer_type: :spatial)
      h = buffer.to_h
      expect(h[:by_type][:verbal]).to eq(1)
      expect(h[:by_type][:spatial]).to eq(1)
      expect(h[:by_type][:episodic]).to eq(0)
    end
  end
end
