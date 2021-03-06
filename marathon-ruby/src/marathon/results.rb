# $Id: results.rb 260 2009-01-13 05:53:15Z kd $
# 
include_class 'net.sourceforge.marathon.api.SourceLine'

class Collector
  def initialize()
    @playbackresult = nil
    @exclude = nil
  end

  def callprotected(function, result, *args)
    @playbackresult = result
      begin
        function.call(*args)
		  return 1
		rescue NativeException => e
		  addjavaerror(e)
		  raise
		rescue => e
		  addpythonerror(e)
		  raise
      end
      return 0
  end

  def addfailure(exception, result)
    @playbackresult = result
    backtrace = nil
    begin
      raise NameError
    rescue
      backtrace = $!.backtrace
    end
	_addfailure(exception.message, backtrace)
  end

  def addpythonerror(exception)
    _addfailure(exception.to_s + ": " + exception.message.to_s, exception.backtrace)
  end

  def addjavaerror(exception)
    _addfailure(exception.message, exception.backtrace)
  end

  def _addfailure(message, backtrace)
    java.lang.System.err.println backtrace.inspect
    lines = convert(backtrace)
    @playbackresult.addFailure(message, lines.to_java(SourceLine))
  end

  def convert(backtrace)
    backtrace.find { |item| not excluded(item) }.map { |line|
      java.lang.System.err.println line.inspect
      b = line.split(':')
      fname = "Unknown"
      fname = b[2].match("`(.*)'").to_a[1] if b[2]
      SourceLine.new(b[0], fname, b[1].to_i)
    }
  end

  def excluded(item)
    file = item.split(':')[0]
    file == __FILE__ or file.match('playback.rb$') != nil or file.match('file$') or file == "classpath"
  end
end
