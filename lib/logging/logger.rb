module Hadope
  class LoggerSingleton

    attr_writer :show_timing_info

    VERBOSE_MODE_DEFAULT = false
    LOG_TO_FILE_DEFAULT = false
    TIMING_INFO_DEFAULT = false

    class << self
      attr_accessor :singleton

      def get
        @singleton ||= new
      end
    end

    def initialize
      @log_path = File.expand_path './.hadopelog'
      @verbose_mode = VERBOSE_MODE_DEFAULT
      @log_to_file = LOG_TO_FILE_DEFAULT
      @show_timing_info = TIMING_INFO_DEFAULT
    end

    def loud_mode
      @verbose_mode = true
    end

    def quiet_mode
      @verbose_mode = false
    end

    def timing_info info
      puts info if @show_timing_info
    end

    def log(action)
      log_line = "[#{Time.now}] #{action}"
      puts log_line if @verbose_mode
      File.open(@log_path, 'a') { |f| f.puts log_line } if @log_to_file
    end

  end

  Logger = LoggerSingleton.get

end
