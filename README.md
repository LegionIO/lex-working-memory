# lex-working-memory

Baddeley & Hitch Working Memory Model for LegionIO cognitive agents. Capacity-limited buffer (7 ± 2 items) with priority-based activation, decay, rehearsal, chunking, and consolidation candidacy detection.

## What It Does

`lex-working-memory` provides a structured active-item buffer. Items are stored with a priority level that sets initial activation. Each tick, activations decay; rehearsal resets age and boosts activation. When the buffer is full, lowest-activation items are evicted. Items with sustained high activation (>= 0.8) become consolidation candidates for transfer to long-term memory via `lex-memory`.

- **Capacity**: 7 base + up to 3 chunking bonus (items sharing a tag count as a chunk)
- **Buffer types**: `:verbal`, `:spatial`, `:episodic`
- **Priority levels**: critical (1.0), high (0.75), normal (0.5), low (0.25), background (0.1)
- **Decay**: -0.15 activation per tick; expires at 30 ticks or 0 activation
- **Rehearsal**: +0.3 activation, resets age
- **Interference detection**: items with same buffer_type + shared tag + close activation values

## Usage

```ruby
require 'legion/extensions/working_memory'

client = Legion::Extensions::WorkingMemory::Client.new

# Store items
result = client.store_item(
  content: 'meeting at 3pm',
  buffer_type: :verbal,
  priority: :high,
  tags: [:schedule, :today]
)
item_id = result[:item_id]
# activation: 0.75 (high priority), load: 0.14

# Rehearse to keep it active
client.rehearse_item(item_id: item_id)
# => { activation: 1.0 }

# Retrieve by tag
client.retrieve_by_tag(tag: :today)
# => { items: [...], count: 1 }

# Buffer status
client.buffer_status
# => { item_count: 1, capacity: 7, load: 0.14, load_level: :light, full: false }

# Find interference (items that may confuse each other)
client.find_interference
# => { interference_pairs: [], count: 0 }

# Consolidation candidates (activation >= 0.8 after rehearsal)
client.consolidation_candidates
# => { candidates: [{ item_id:, content:, activation: }], count: 1 }

# Per-tick update (decay + return consolidation candidates)
client.update_working_memory
# => { expired_count: 0, consolidation_candidates: [...] }

# Clear everything
client.clear_buffer
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
