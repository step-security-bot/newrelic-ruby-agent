# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/transaction_event_aggregator'
require 'new_relic/agent/synthetics_event_aggregator'
require 'new_relic/agent/transaction_event_primitive'
require 'json'

module NewRelic
  module Agent
    # This is responsible for recording transaction events and managing
    # the relationship between events generated from synthetics requests
    # vs normal requests.
    class TransactionEventRecorder
      attr_reader :transaction_event_aggregator
      attr_reader :synthetics_event_aggregator

      def initialize(events)
        @transaction_event_aggregator = NewRelic::Agent::TransactionEventAggregator.new(events)
        @synthetics_event_aggregator = NewRelic::Agent::SyntheticsEventAggregator.new(events)
      end

      def record(payload)
        NewRelic::Agent.logger.debug("#{Thread.current.object_id} WALUIGI TransactionEventRecorder#record   EVENTS NOT ENABLED") if !NewRelic::Agent.config[:'transaction_events.enabled']
        return unless NewRelic::Agent.config[:'transaction_events.enabled']

        if synthetics_event?(payload)
          event = create_event(payload)

          begin
            NewRelic::Agent.logger.debug(
              "#{Thread.current.object_id} WALUIGI TransactionEventRecorder#record  SYNTHETICS   self: #{self.object_id} aggregator: #{transaction_event_aggregator.object_id}  Payload:\n    " \
              "#{JSON.pretty_generate(event)}" \
              "------END PAYLOAD------------------------------------------------------------\n    "
            )
          rescue => e
            NewRelic::Agent.logger.warn(" #{Thread.current.object_id}- WALUIGI: TransactionEventRecorder#record SYNTHETICS error ", e)
          end

          result = synthetics_event_aggregator.record(event)
          transaction_event_aggregator.record(event: event) if result.nil?
        else
          event = create_event(payload)

          begin
            NewRelic::Agent.logger.debug(
              "#{Thread.current.object_id} WALUIGI TransactionEventRecorder#record  self: #{self.object_id} aggregator: #{transaction_event_aggregator.object_id}   Payload:\n    " \
              "#{JSON.pretty_generate(event)}" \
              "------END PAYLOAD------------------------------------------------------------\n    "
            )
          rescue => e
            NewRelic::Agent.logger.warn(" #{Thread.current.object_id}- WALUIGI: TransactionEventRecorder#record error ", e)
          end

          transaction_event_aggregator.record(priority: payload[:priority], event: event)
        end
      end

      def create_event(payload)
        TransactionEventPrimitive.create(payload)
      end

      def synthetics_event?(payload)
        payload.key?(:synthetics_resource_id)
      end

      def drop_buffered_data
        transaction_event_aggregator.reset!
        synthetics_event_aggregator.reset!
      end
    end
  end
end
