# frozen_string_literal: true

require_relative 'working_memory/version'
require_relative 'working_memory/helpers/constants'
require_relative 'working_memory/helpers/buffer_item'
require_relative 'working_memory/helpers/buffer'
require_relative 'working_memory/runners/working_memory'
require_relative 'working_memory/client'

module Legion
  module Extensions
    module WorkingMemory
      extend Legion::Extensions::Core if defined?(Legion::Extensions::Core)
    end
  end
end
