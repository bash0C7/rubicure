module Rubicure
  class Series < Hash
    include Hashie::Extensions::MethodAccess

    @@cache = {}
    @@config = nil

    # @param [Time,Date,String] arg Time, Date or date like String (ex. "2013-12-16")
    def on_air?(arg)
      date = to_date(arg)
      if respond_to?(:started_date)
        if respond_to?(:ended_date)
          # ended title
          return (started_date .. ended_date).cover?(date)
        else
          # on air title
          return started_date <= date
        end
      end

      false
    end

    # @return [Array<Rubicure::Girl>]
    def girls
      unless @girls
        @girls = []
        if has_key?(:girls)
          fetch(:girls).each do |girl_name|
            girl = Rubicure::Girl.find(girl_name.to_sym)

            # FIXME
            unless ["シャイニールミナス", "ミルキィローズ"].include?(girl.precure_name)
              girl.transform_message = "#{fetch(:before_transform_message,"")}#{girl.transform_message}#{fetch(:after_transform_message,"")}"
            end

            @girls << girl
          end
        end
      end

      @girls
    end

    # @return [Array<Symbol>]
    def self.names
      config.keys
    end

    # @return [Hash] content of config/series.yml
    def self.config
      unless @@config
        config_file = "#{File.dirname(__FILE__)}/../../config/series.yml"
        @@config = YAML.load_file(config_file).deep_symbolize_keys
      end
      @@config
    end

    # @return [Hash] content of config/precure.yml
    def self.reload_config!
      @@cache = {}
      @@config = nil
      config
    end

    # @param [Symbol] series_name
    def self.valid?(series_name)
      names.include?(series_name)
    end

    # @param series_name [Symbol]
    # @return [Rubicure::Series]
    # @raise arg is not precure
    def self.find(series_name)
      raise "unknown series: #{series_name}" unless valid?(series_name)

      unless @@cache[series_name]
        series_config = config[series_name] || {}
        series_config.reject! { |k, v| v.nil? }

        @@cache[series_name] = Rubicure::Series[series_config]
      end

      @@cache[series_name]
    end

    private
      # @param arg
      # @return [Date] arg is String or Date
      # @return [Time] arg is Time
      # @return [nil] arg is other
      def to_date(arg)
        case arg
          when Date, Time
            arg
          when String
            Date.parse(arg)
          else
            nil
        end
      end
  end
end
