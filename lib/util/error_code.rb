# frozen_string_literal: true

module Util
  # helps get information regarding current error codes.
  class ErrorCode
    def initialize(path)
      @path = path
      validate
    end

    def next_available
      code_lines = File.foreach(@path).select {|line| /code: \"CONJ[0-9]+E\"/.match(line)}
      codes = code_lines&.map { |match| /[0-9]+/.match(match)[0].to_i }
      err_num = codes ? codes.max : -1
      puts(error_code(err_num+1))
    end

    def validate
      msg = format("The following path:%s was not found", @path)
      raise FileNotFound, msg unless File.file?(@path)
    end

    def error_code(num)
      if num.zero?
        "The file doesn't contain any error messages"
      else
        format("The next available error number is %d ( CONJ%05dE )", num, num)
      end
    end
  end
end

# Error is raised when a file is not found
class FileNotFound < StandardError
  def initialize(msg = "File Not Found")
    super
  end
end
