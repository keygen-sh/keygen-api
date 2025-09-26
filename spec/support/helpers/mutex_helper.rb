# frozen_string_literal: true

module MutexHelper
  class Once
    def initialize
      @mutex = Mutex.new
      @done  = false
    end

    def synchronize
      return if @done

      @mutex.synchronize do
        return if @done

        yield

        @done = true
      end
    end
  end
end
