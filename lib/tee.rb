require 'tee/version'

# @attr stdout [IO]
class Tee
  class << self
    # @overload open(*ios, options = {})
    #   A synonym for Tee.new
    #   @param (see #initialize)
    #   @return [Tee]
    #
    # @overload open(*ios, options = {}, &block)
    #   It will be passed the Tee as an argument,
    #   and the Tee will automatically be closed when the block terminates.
    #   @param (see #initialize)
    #   @yieldparam tee [Tee]
    #   @return the value of the block
    def open(*args, &block)
      if block_given?
        tee = new(*args)
        begin
          yield tee
        ensure
          tee.send(:close_ios_opened_by_tee)
        end
      else
        new(*args)
      end
    end
  end

  attr_accessor :stdout

  # @overload initialize(*ios, options = {})
  #   @param ios [Array<IO,String>]
  #   @param options [Hash]
  #   @option options [String, Fixnum] :mode
  #   @option options [Fixnum] :perm
  #   @option options [IO, nil] :stdout
  def initialize(*ios)
    @options = { mode: 'w' }
    @options.update(ios.pop) if ios.last.is_a?(Hash)

    @stdout = @options.key?(:stdout) ? @options.delete(:stdout) : $stdout

    @ios = []
    add(*ios)
  end

  # Add IOs
  #
  # @param ios [Array<IO,String>]
  # @return [self]
  def add(*ios)
    open_args = [@options[:mode]]
    open_args << @options[:perm] if @options[:perm]

    _ios = []
    begin
      ios.each do |io|
        _ios << (
          io.respond_to?(:write) ?
            [io, false] :
            [File.open(io, *open_args), true]
        )
      end
    rescue => e
      close_ios_opened_by_tee(_ios) rescue nil
      raise e
    end
    @ios.concat(_ios)

    self
  end

  # Closes all IOs
  #
  # @return [nil]
  def close
    @ios.each { |io,| io.close }
    nil
  end

  # Returns self
  #
  # @return [self]
  def to_io
    self
  end

  %w(
    <<
    flush
    print
    printf
    putc
    puts
    syswrite
    write
    write_nonblock
  ).each do |method|
    class_eval(<<-EOS, __FILE__, __LINE__ + 1)
      def #{method}(*args)
        @ios.each { |io,| io.send(:#{method}, *args) }
        @stdout.send(:#{method}, *args) if @stdout
      end
    EOS
  end

  private

  def close_ios_opened_by_tee(ios = @ios)
    ios.each { |io, opened| io.close if opened }
    nil
  end
end
