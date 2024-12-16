# frozen_string_literal: true

class EnumeratorIO
  def initialize(enum)
    @enum   = enum
    @buffer = ''.b
    @eof    = false
  end

  def eof? = @eof && @buffer.empty?
  def read(length = nil, buffer = nil)
    buffer ||= +''
    buffer.clear

    # fill the buffer until it has enough data or EOF
    while !@eof && (length.nil? || @buffer.bytesize < length)
      begin
        @buffer << @enum.next
      rescue StopIteration
        @eof = true

        break
      end
    end

    # extract the requested amount of data from the buffer
    if length
      buffer << @buffer.slice!(0, length)
    else
      buffer << @buffer

      @buffer.clear
    end

    buffer.empty? ? nil : buffer
  end
end
