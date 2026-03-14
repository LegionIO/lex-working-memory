# frozen_string_literal: true

module Legion
  module Extensions
    module WorkingMemory
      class Client
        include Runners::WorkingMemory

        attr_reader :buffer

        def initialize(buffer: nil, **)
          @buffer = buffer || Helpers::Buffer.new
        end
      end
    end
  end
end
