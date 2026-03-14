# frozen_string_literal: true

require_relative 'lib/legion/extensions/working_memory/version'

Gem::Specification.new do |spec|
  spec.name          = 'legion-extensions-working-memory'
  spec.version       = Legion::Extensions::WorkingMemory::VERSION
  spec.authors       = ['Matthew Iverson']
  spec.email         = ['matt@legionIO.com']
  spec.summary       = 'Working memory buffer for LegionIO cognitive agents'
  spec.description   = 'Short-term active maintenance of task-relevant information with capacity limits, decay, and rehearsal'
  spec.homepage      = 'https://github.com/LegionIO/lex-working-memory'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.files = Dir['lib/**/*']
  spec.require_paths = ['lib']

  spec.metadata['rubygems_mfa_required'] = 'true'
end
