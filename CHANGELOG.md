# Changelog

## [0.1.1] - 2026-03-18

### Fixed
- Validate `buffer_type` against `BUFFER_TYPES` in `Buffer#store` — rejects types not in `[:verbal, :spatial, :episodic]`
- Validate `priority` against `PRIORITY_LEVELS` in `Buffer#store` — rejects priorities not in `[:critical, :high, :normal, :low, :background]`

## [0.1.0] - 2026-03-13

### Added
- Initial release: Baddeley & Hitch working memory model
- Capacity-limited buffer (Miller's Law: 7 +/- 2), chunking, rehearsal, interference detection
- Consolidation candidate detection for long-term memory transfer
- Standalone Client
