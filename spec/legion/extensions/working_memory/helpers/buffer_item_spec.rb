# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::WorkingMemory::Helpers::BufferItem do
  subject(:item) { described_class.new(content: 'test content', buffer_type: :verbal, priority: :normal, tags: [:test]) }

  describe '#initialize' do
    it 'generates a uuid id' do
      expect(item.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores content' do
      expect(item.content).to eq('test content')
    end

    it 'stores buffer_type' do
      expect(item.buffer_type).to eq(:verbal)
    end

    it 'stores priority' do
      expect(item.priority).to eq(:normal)
    end

    it 'stores tags' do
      expect(item.tags).to eq([:test])
    end

    it 'sets activation from priority level' do
      expect(item.activation).to eq(0.5)
    end

    it 'sets critical priority to 1.0 activation' do
      critical = described_class.new(content: 'urgent', priority: :critical)
      expect(critical.activation).to eq(1.0)
    end

    it 'sets low priority to 0.25 activation' do
      low = described_class.new(content: 'low', priority: :low)
      expect(low.activation).to eq(0.25)
    end

    it 'starts with zero rehearsal count' do
      expect(item.rehearsal_count).to eq(0)
    end

    it 'starts with zero age ticks' do
      expect(item.age_ticks).to eq(0)
    end

    it 'records created_at' do
      expect(item.created_at).to be_a(Time)
    end

    it 'defaults buffer_type to episodic' do
      default_item = described_class.new(content: 'x')
      expect(default_item.buffer_type).to eq(:episodic)
    end

    it 'defaults tags to empty array' do
      default_item = described_class.new(content: 'x')
      expect(default_item.tags).to eq([])
    end
  end

  describe '#rehearse' do
    it 'increments rehearsal count' do
      item.rehearse
      expect(item.rehearsal_count).to eq(1)
    end

    it 'boosts activation' do
      initial = item.activation
      item.rehearse
      expect(item.activation).to eq(initial + Legion::Extensions::WorkingMemory::Helpers::Constants::REHEARSAL_BOOST)
    end

    it 'caps activation at 1.0' do
      critical = described_class.new(content: 'urgent', priority: :critical)
      critical.rehearse
      expect(critical.activation).to eq(1.0)
    end

    it 'resets age ticks to zero' do
      item.decay
      item.decay
      expect(item.age_ticks).to eq(2)
      item.rehearse
      expect(item.age_ticks).to eq(0)
    end
  end

  describe '#decay' do
    it 'increments age ticks' do
      item.decay
      expect(item.age_ticks).to eq(1)
    end

    it 'reduces activation' do
      initial = item.activation
      item.decay
      expect(item.activation).to eq(initial - Legion::Extensions::WorkingMemory::Helpers::Constants::DECAY_RATE)
    end

    it 'floors activation at 0.0' do
      bg = described_class.new(content: 'bg', priority: :background)
      10.times { bg.decay }
      expect(bg.activation).to eq(0.0)
    end
  end

  describe '#expired?' do
    it 'is not expired when fresh' do
      expect(item.expired?).to be false
    end

    it 'expires when activation reaches zero' do
      bg = described_class.new(content: 'bg', priority: :background)
      10.times { bg.decay }
      expect(bg.expired?).to be true
    end

    it 'expires when age exceeds MAX_AGE_TICKS' do
      Legion::Extensions::WorkingMemory::Helpers::Constants::MAX_AGE_TICKS.times { item.decay }
      expect(item.expired?).to be true
    end
  end

  describe '#consolidation_ready?' do
    it 'returns false for normal priority items' do
      expect(item.consolidation_ready?).to be false
    end

    it 'returns true for critical priority items' do
      critical = described_class.new(content: 'urgent', priority: :critical)
      expect(critical.consolidation_ready?).to be true
    end

    it 'returns true after enough rehearsals' do
      3.times { item.rehearse }
      expect(item.activation).to be >= Legion::Extensions::WorkingMemory::Helpers::Constants::CONSOLIDATION_THRESHOLD
      expect(item.consolidation_ready?).to be true
    end
  end

  describe '#interferes_with?' do
    let(:other) { described_class.new(content: 'other', buffer_type: :verbal, priority: :normal, tags: [:test]) }

    it 'detects interference between same-type same-tag items with similar activation' do
      expect(item.interferes_with?(other)).to be true
    end

    it 'returns false for different buffer types' do
      spatial = described_class.new(content: 'spatial', buffer_type: :spatial, priority: :normal, tags: [:test])
      expect(item.interferes_with?(spatial)).to be false
    end

    it 'returns false for non-overlapping tags' do
      no_overlap = described_class.new(content: 'other', buffer_type: :verbal, priority: :normal, tags: [:different])
      expect(item.interferes_with?(no_overlap)).to be false
    end

    it 'returns false for non-BufferItem objects' do
      expect(item.interferes_with?('not an item')).to be false
    end

    it 'returns false when activation difference exceeds threshold' do
      critical = described_class.new(content: 'urgent', buffer_type: :verbal, priority: :critical, tags: [:test])
      low = described_class.new(content: 'low', buffer_type: :verbal, priority: :low, tags: [:test])
      expect(critical.interferes_with?(low)).to be false
    end
  end

  describe '#to_h' do
    it 'returns a hash with all fields' do
      h = item.to_h
      expect(h).to include(:id, :content, :buffer_type, :priority, :activation, :rehearsal_count, :age_ticks, :expired, :consolidation_ready)
    end

    it 'rounds activation to 4 decimal places' do
      item.decay
      expect(item.to_h[:activation]).to eq(item.activation.round(4))
    end
  end
end
