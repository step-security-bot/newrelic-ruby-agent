# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'instrumentation'

module NewRelic
  module Agent
    module Instrumentation
      module MonitoredThread
        module Prepend
          include NewRelic::Agent::Instrumentation::MonitoredThread

          def initialize(*args, &block)
            traced_block = add_thread_tracing(*args, &block)
            super(*args, &traced_block)
          end
        end
      end

      module MonitoredFiber
        module Prepend
          include NewRelic::Agent::Instrumentation::MonitoredFiber

          def initialize(*args, &block)
            traced_block = add_fiber_tracing(*args, &block)
            super(*args, &traced_block)
          end
        end
      end
    end
  end
end
