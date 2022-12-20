# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    class Transaction
      module Tracing
        attr_reader :current_segment_by_thread

        def async?
          @async ||= false
        end

        attr_writer :async

        def total_time
          @total_time ||= 0.0
        end

        attr_writer :total_time

        def add_segment(segment, parent = nil)
          segment.transaction = self
          segment.parent = parent || current_segment
          # segment.name = "#{segment.name}//////parent_name_'#{segment.parent&.name&.slice(0, 20)}'"
          set_current_segment(segment)
          if @segments.length < segment_limit
            @segments << segment
          else
            segment.record_on_finish = true
            ::NewRelic::Agent.logger.debug("Segment limit of #{segment_limit} reached, ceasing collection.")
          end
          segment.transaction_assigned
        end

        def segment_complete(segment)
          if segment.parent && segment.parent.starting_segment_key != Tracer.current_segment_key
            # if leaving fiber/thread, do we even need to do anything?

            # WHAT DOES THIS MEAN FOR WHEN STORING SPANS ON THREAD LOCAL
            # its deleting things too early currently
            # i think it's bc a fiber can complete before a thread that was nested inside of it actually starts
            # we can't really just never delete it though, right? it would increase memory usage too much
            # or would it? bc the segments STILL EXIST SOMEWHERE, and ruby is all about that pass by reference life
            # or maybe we could update the agent to always pass in a parent when creating a segment to avoid the problem.
            # thats prbly a better way to do it in general tbh

            # remove_current_segment_by_thread_id(current_segment_key)
          else
            set_current_segment(segment.parent)
          end
        end

        def segment_limit
          Agent.config[:'transaction_tracer.limit_segments']
        end

        private

        def finalize_segments
          segments.each { |s| s.finalize }
        end

        WEB_TRANSACTION_TOTAL_TIME = "WebTransactionTotalTime".freeze
        OTHER_TRANSACTION_TOTAL_TIME = "OtherTransactionTotalTime".freeze

        def record_total_time_metrics
          total_time_metric = if recording_web_transaction?
            WEB_TRANSACTION_TOTAL_TIME
          else
            OTHER_TRANSACTION_TOTAL_TIME
          end

          @metrics.record_unscoped(total_time_metric, total_time)
          @metrics.record_unscoped("#{total_time_metric}/#{@frozen_name}", total_time)
        end
      end
    end
  end
end
