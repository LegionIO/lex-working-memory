# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::WorkingMemory::Helpers::Constants do
  describe 'CAPACITY' do
    it 'is 7 (Miller\'s Law)' do
      expect(described_class::CAPACITY).to eq(7)
    end
  end

  describe 'CHUNK_BONUS' do
    it 'is a positive integer' do
      expect(described_class::CHUNK_BONUS).to be_a(Integer)
      expect(described_class::CHUNK_BONUS).to be > 0
    end
  end

  describe 'BUFFER_TYPES' do
    it 'contains verbal, spatial, and episodic' do
      expect(described_class::BUFFER_TYPES).to contain_exactly(:verbal, :spatial, :episodic)
    end

    it 'is frozen' do
      expect(described_class::BUFFER_TYPES).to be_frozen
    end
  end

  describe 'DECAY_RATE' do
    it 'is a positive float between 0 and 1' do
      expect(described_class::DECAY_RATE).to be_a(Float)
      expect(described_class::DECAY_RATE).to be_between(0.0, 1.0).exclusive
    end
  end

  describe 'REHEARSAL_BOOST' do
    it 'is a positive float between 0 and 1' do
      expect(described_class::REHEARSAL_BOOST).to be_a(Float)
      expect(described_class::REHEARSAL_BOOST).to be_between(0.0, 1.0).exclusive
    end
  end

  describe 'PRIORITY_LEVELS' do
    it 'has five levels' do
      expect(described_class::PRIORITY_LEVELS.size).to eq(5)
    end

    it 'is ordered from highest to lowest activation' do
      values = described_class::PRIORITY_LEVELS.values
      expect(values).to eq(values.sort.reverse)
    end

    it 'has critical at 1.0' do
      expect(described_class::PRIORITY_LEVELS[:critical]).to eq(1.0)
    end

    it 'is frozen' do
      expect(described_class::PRIORITY_LEVELS).to be_frozen
    end
  end

  describe 'MAX_AGE_TICKS' do
    it 'is a positive integer' do
      expect(described_class::MAX_AGE_TICKS).to be_a(Integer)
      expect(described_class::MAX_AGE_TICKS).to be > 0
    end
  end

  describe 'INTERFERENCE_THRESHOLD' do
    it 'is a float between 0 and 1' do
      expect(described_class::INTERFERENCE_THRESHOLD).to be_between(0.0, 1.0)
    end
  end

  describe 'CONSOLIDATION_THRESHOLD' do
    it 'is a float between 0 and 1' do
      expect(described_class::CONSOLIDATION_THRESHOLD).to be_between(0.0, 1.0)
    end

    it 'is higher than normal priority activation' do
      expect(described_class::CONSOLIDATION_THRESHOLD).to be > described_class::PRIORITY_LEVELS[:normal]
    end
  end

  describe 'LOAD_LEVELS' do
    it 'has five levels' do
      expect(described_class::LOAD_LEVELS.size).to eq(5)
    end

    it 'is ordered from highest to lowest threshold' do
      values = described_class::LOAD_LEVELS.values
      expect(values).to eq(values.sort.reverse)
    end

    it 'is frozen' do
      expect(described_class::LOAD_LEVELS).to be_frozen
    end
  end
end
