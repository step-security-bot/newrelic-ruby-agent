# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Instrumentation
      module MonitoredThread
        def add_thread_tracing(*args, &block)
          NewRelic::Agent::Tracer.thread_block_with_current_segment(*args, segment_name: 'Ruby/Thread', &block)
        end
      end

      module MonitoredFiber
        def add_fiber_tracing(*args, &block)
          NewRelic::Agent::Tracer.thread_block_with_current_segment(*args, segment_name: 'Ruby/Fiber', &block)
        end
      end
    end
  end
end
