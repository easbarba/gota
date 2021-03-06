# frozen_string_literal: true

module Gota
  # Control commands to the PulseAudio sound server.
  class Pactl
    STEP = 3

    attr_accessor :name, :state

    def initialize(state)
      @name = 'pactl'
      @state = state
    end

    def sink
      require 'English'

      output = `set -eu; pactl list sinks`
      raise('pipeline failed') unless $CHILD_STATUS.success?

      output.split('Sink #').find do |sink|
        sink if sink.include? 'State: RUNNING'
      end.split('State').first.strip # sink id is the first letter in the string returned
    end

    def toggle
      "set-sink-mute #{sink} toggle"
    end

    def updown
      "set-sink-volume #{sink} #{state}#{STEP}%"
    end

    def to_s
      "#{name} #{sink} #{state}"
    end
  end
end
