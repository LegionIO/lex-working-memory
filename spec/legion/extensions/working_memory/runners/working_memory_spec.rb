# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::WorkingMemory::Runners::WorkingMemory do
  let(:runner) do
    obj = Object.new
    obj.extend(described_class)
    obj
  end

  describe '#update_working_memory' do
    it 'returns success with buffer status' do
      result = runner.update_working_memory
      expect(result[:success]).to be true
      expect(result[:status]).to be_a(Hash)
      expect(result[:consolidation_candidates]).to be_an(Array)
    end

    it 'decays items on tick' do
      runner.store_item(content: 'decaying', priority: :normal)
      item_id = runner.buffer.items.first.id
      initial = runner.buffer.items.first.activation
      runner.update_working_memory
      expect(runner.buffer.retrieve(item_id).activation).to be < initial
    end

    it 'removes expired items on tick' do
      runner.store_item(content: 'will expire', priority: :background)
      30.times { runner.update_working_memory }
      expect(runner.buffer.size).to eq(0)
    end
  end

  describe '#store_item' do
    it 'stores an item and returns its hash' do
      result = runner.store_item(content: 'hello world')
      expect(result[:success]).to be true
      expect(result[:item][:content]).to eq('hello world')
      expect(result[:item][:id]).to be_a(String)
    end

    it 'stores with custom parameters' do
      result = runner.store_item(content: 'spatial', buffer_type: :spatial, priority: :high, tags: [:nav])
      expect(result[:item][:buffer_type]).to eq(:spatial)
      expect(result[:item][:priority]).to eq(:high)
    end

    it 'handles full buffer gracefully' do
      15.times { |i| runner.store_item(content: "item #{i}", priority: :critical) }
      result = runner.store_item(content: 'overflow')
      expect(result[:success]).to be true
    end
  end

  describe '#retrieve_item' do
    it 'retrieves a stored item' do
      stored = runner.store_item(content: 'find me')
      result = runner.retrieve_item(id: stored[:item][:id])
      expect(result[:success]).to be true
      expect(result[:item][:content]).to eq('find me')
    end

    it 'returns not_found for missing items' do
      result = runner.retrieve_item(id: 'nonexistent')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#rehearse_item' do
    it 'rehearses an item and boosts activation' do
      stored = runner.store_item(content: 'rehearse me')
      initial = stored[:item][:activation]
      result = runner.rehearse_item(id: stored[:item][:id])
      expect(result[:success]).to be true
      expect(result[:item][:activation]).to be > initial
      expect(result[:item][:rehearsal_count]).to eq(1)
    end

    it 'returns not_found for missing items' do
      result = runner.rehearse_item(id: 'nonexistent')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#retrieve_by_tag' do
    it 'returns items with matching tag' do
      runner.store_item(content: 'a', tags: [:work])
      runner.store_item(content: 'b', tags: [:play])
      runner.store_item(content: 'c', tags: [:work])
      result = runner.retrieve_by_tag(tag: :work)
      expect(result[:success]).to be true
      expect(result[:count]).to eq(2)
    end

    it 'returns empty for unmatched tags' do
      result = runner.retrieve_by_tag(tag: :nothing)
      expect(result[:count]).to eq(0)
    end
  end

  describe '#retrieve_by_type' do
    it 'returns items of specified type' do
      runner.store_item(content: 'v1', buffer_type: :verbal)
      runner.store_item(content: 's1', buffer_type: :spatial)
      result = runner.retrieve_by_type(buffer_type: :verbal)
      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
      expect(result[:items].first[:content]).to eq('v1')
    end
  end

  describe '#remove_item' do
    it 'removes an item by id' do
      stored = runner.store_item(content: 'remove me')
      runner.remove_item(id: stored[:item][:id])
      result = runner.retrieve_item(id: stored[:item][:id])
      expect(result[:success]).to be false
    end
  end

  describe '#buffer_status' do
    it 'returns current buffer status' do
      runner.store_item(content: 'one')
      result = runner.buffer_status
      expect(result[:success]).to be true
      expect(result[:status][:size]).to eq(1)
      expect(result[:status]).to include(:capacity, :load, :load_level, :by_type, :available)
    end
  end

  describe '#consolidation_candidates' do
    it 'returns items ready for consolidation' do
      runner.store_item(content: 'critical', priority: :critical)
      runner.store_item(content: 'normal', priority: :normal)
      result = runner.consolidation_candidates
      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
      expect(result[:candidates].first[:content]).to eq('critical')
    end
  end

  describe '#working_memory_stats' do
    it 'returns comprehensive stats' do
      runner.store_item(content: 'one')
      result = runner.working_memory_stats
      expect(result[:success]).to be true
      expect(result[:size]).to eq(1)
      expect(result).to include(:capacity, :load, :load_level, :full, :available)
    end

    it 'reports full when at capacity' do
      15.times { |i| runner.store_item(content: "item #{i}", priority: :critical) }
      result = runner.working_memory_stats
      expect(result[:full]).to be true
    end
  end

  describe '#clear_buffer' do
    it 'empties the buffer' do
      3.times { |i| runner.store_item(content: "item #{i}") }
      result = runner.clear_buffer
      expect(result[:success]).to be true
      expect(runner.buffer.size).to eq(0)
    end
  end

  describe '#find_interference' do
    it 'finds interfering items' do
      runner.store_item(content: 'a', buffer_type: :verbal, priority: :normal, tags: [:topic])
      stored = runner.store_item(content: 'b', buffer_type: :verbal, priority: :normal, tags: [:topic])
      result = runner.find_interference(id: stored[:item][:id])
      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
    end

    it 'returns not_found for missing items' do
      result = runner.find_interference(id: 'nonexistent')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end

    it 'does not include the item itself' do
      stored = runner.store_item(content: 'alone', buffer_type: :verbal, priority: :normal, tags: [:solo])
      result = runner.find_interference(id: stored[:item][:id])
      expect(result[:count]).to eq(0)
    end
  end
end
