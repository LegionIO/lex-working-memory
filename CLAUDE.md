# lex-working-memory

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-working-memory`
- **Version**: `0.1.1`
- **Namespace**: `Legion::Extensions::WorkingMemory`

## Purpose

Implements Baddeley & Hitch's Working Memory Model for cognitive agents. A capacity-limited buffer (Miller's Law: 7 ± 2 items) holds active items with priority-based activation. Items decay each tick; rehearsal resets age and boosts activation. Related items can interfere. Chunking allows grouped items to count for more capacity. Supports consolidation candidate detection for long-term memory transfer.

## Gem Info

- **Gem name**: `lex-working-memory`
- **License**: MIT
- **Ruby**: >= 3.4
- **No runtime dependencies** beyond the Legion framework

## File Structure

```
lib/legion/extensions/working_memory/
  version.rb                          # VERSION = '0.1.0'
  helpers/
    constants.rb                      # CAPACITY, CHUNK_BONUS, BUFFER_TYPES, DECAY_RATE, priorities, etc.
    buffer_item.rb                    # BufferItem class — single active item with activation tracking
    buffer.rb                         # Buffer class — capacity-limited store with chunking and interference
  runners/
    working_memory.rb                 # Runners::WorkingMemory module — all public runner methods
  client.rb                           # Client class including Runners::WorkingMemory
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `CAPACITY` | 7 | Base working memory capacity (Miller's Law) |
| `CHUNK_BONUS` | 3 | Maximum additional capacity from chunking |
| `BUFFER_TYPES` | 3 symbols | `:verbal`, `:spatial`, `:episodic` |
| `DECAY_RATE` | 0.15 | Per-tick activation decrease |
| `REHEARSAL_BOOST` | 0.3 | Activation increase on rehearsal |
| `PRIORITY_LEVELS` | hash | `{ critical: 1.0, high: 0.75, normal: 0.5, low: 0.25, background: 0.1 }` |
| `MAX_AGE_TICKS` | 30 | Maximum age before expiry |
| `INTERFERENCE_THRESHOLD` | 0.7 | Minimum activation difference for interference check |
| `CONSOLIDATION_THRESHOLD` | 0.8 | Minimum activation for consolidation candidacy |
| `LOAD_LEVELS` | hash | Named load tiers: `light`, `moderate`, `heavy`, `overloaded` based on capacity fraction |

## Helpers

### `Helpers::BufferItem`

Single active item with activation tracking.

- `initialize(id:, content:, buffer_type: :verbal, priority: :normal, tags: [])` — activation = PRIORITY_LEVELS[priority]; age_ticks=0
- `rehearse` — increments activation by REHEARSAL_BOOST; clamps to 1.0; resets age_ticks to 0
- `decay` — increments age_ticks; decrements activation by DECAY_RATE; floors activation at 0.0
- `expired?` — `age_ticks >= MAX_AGE_TICKS || activation <= 0.0`
- `consolidation_ready?` — `activation >= CONSOLIDATION_THRESHOLD`
- `interferes_with?(other)` — `buffer_type == other.buffer_type && (tags & other.tags).any? && (activation - other.activation).abs < INTERFERENCE_THRESHOLD`

### `Helpers::Buffer`

Capacity-limited working memory buffer with chunking and interference detection.

- `initialize` — items hash keyed by id, chunk_groups hash keyed by tag
- `store(content:, buffer_type: :verbal, priority: :normal, tags: [])` — creates BufferItem; if at capacity, evicts lowest-activation item before adding; returns new item
- `retrieve(item_id)` — returns item by id; nil if absent
- `retrieve_by_tag(tag)` — returns all items with matching tag
- `retrieve_by_type(buffer_type)` — returns all items of given buffer_type
- `rehearse(item_id)` — calls `item.rehearse`
- `remove(item_id)` — deletes item
- `tick_decay` — calls `decay` on all items; removes expired items
- `consolidation_candidates` — items with `consolidation_ready? == true`
- `current_load` — `items.size.to_f / capacity`
- `load_level` — maps current_load to LOAD_LEVELS label
- `capacity` — `CAPACITY + chunk_bonus` where `chunk_bonus` = number of tags that have 2+ items grouped under the same tag, up to CHUNK_BONUS
- `full?` — `items.size >= capacity`
- `clear` — removes all items
- `find_interference` — pairs of items where `interferes_with?` returns true

## Runners

All runners are in `Runners::WorkingMemory`. The `Client` includes this module and owns a `Buffer` instance.

| Runner | Parameters | Returns |
|---|---|---|
| `update_working_memory` | `tick_results: {}` | `{ success:, expired_count:, consolidation_candidates: }` — calls `tick_decay` + returns consolidation list |
| `store_item` | `content:, buffer_type: :verbal, priority: :normal, tags: []` | `{ success:, item_id:, activation:, buffer_type:, load: }` |
| `retrieve_item` | `item_id:` | `{ success:, found:, item: }` |
| `rehearse_item` | `item_id:` | `{ success:, item_id:, activation: }` |
| `retrieve_by_tag` | `tag:` | `{ success:, tag:, items:, count: }` |
| `retrieve_by_type` | `buffer_type:` | `{ success:, buffer_type:, items:, count: }` |
| `remove_item` | `item_id:` | `{ success: }` |
| `buffer_status` | (none) | `{ success:, item_count:, capacity:, load:, load_level:, full: }` |
| `consolidation_candidates` | (none) | `{ success:, candidates:, count: }` |
| `working_memory_stats` | (none) | Count, capacity, load, mean activation, type distribution |
| `clear_buffer` | (none) | `{ success:, cleared_count: }` |
| `find_interference` | (none) | `{ success:, interference_pairs:, count: }` |

## Integration Points

- **lex-tick / lex-cortex**: `update_working_memory` wired as a tick phase handler runs decay and returns consolidation candidates to the `memory_consolidation` phase
- **lex-memory**: consolidation candidates from working memory are promoted to lex-memory as long-term traces when `consolidation_ready? == true` and activation >= 0.8
- **lex-volition**: working memory cognitive load (`current_load`) feeds into the epistemic drive computation in DriveSynthesizer — high load reduces epistemic drive salience
- **lex-cortex**: the `working_memory_integration` phase handler maps to this extension's `update_working_memory` runner
- **lex-attention**: items in working memory represent the current attentional focus; attention shifts should trigger `store_item` for new items and `remove_item` for displaced ones

## Development Notes

- `capacity` is computed dynamically from the current chunk state — items sharing a tag count as a chunk; the bonus is the number of unique tags with 2+ items grouped under them, capped at `CHUNK_BONUS = 3`
- `INTERFERENCE_THRESHOLD = 0.7` is the threshold for the activation *difference* — pairs where activations are within 0.7 of each other AND share a tag AND share a buffer_type are flagged as interfering; this models pro-active and retro-active interference
- `evict lowest-activation` on overflow means low-priority background items are pushed out by high-priority arrivals — this matches the capacity-limited nature of the model
- `tick_decay` removes expired items in the same pass as decay — no separate GC step needed
- `CONSOLIDATION_THRESHOLD = 0.8` ensures only items that have been rehearsed (activation boosted) qualify for consolidation; passively-held items decay away without being consolidated
- `Buffer#store` validates `buffer_type` against `BUFFER_TYPES` and `priority` against `PRIORITY_LEVELS` — returns nil for invalid values
