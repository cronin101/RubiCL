class Hadope::Logger

  VERBOSE_MODE_DEFAULT = true
  LOG_TO_FILE_DEFAULT = true

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
  end

  def loud_mode
    @verbose_mode = true
  end

  def quiet_mode
    @verbose_mode = false
  end

  def log(action)
    log_line = "[#{Time.now}] #{action}"
    puts log_line if @verbose_mode
    File.open(@log_path, "a") { |f| f.puts log_line } if @log_to_file
  end

end
