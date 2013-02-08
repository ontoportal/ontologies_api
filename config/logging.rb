require 'logger'
class CustomLogger < Logger
  alias write <<

  def flush
    ((self.instance_variable_get :@logdev).instance_variable_get :@dev).flush
  end
end

# Setup global logging
require 'rack/logger'
if [:development, :console].include?(settings.environment)
  LOGGER = CustomLogger.new(STDOUT)
  LOGGER.level = Logger::DEBUG
else
  Dir.mkdir('logs') unless File.exist?('logs')
  log = File.new("logs/#{settings.environment}.log", "a+")
  log.sync = true
  LOGGER = CustomLogger.new(log)
  LOGGER.level = Logger::INFO
  $stdout.reopen(log)
  $stderr.reopen(log)
  $stderr.sync = true
  $stdout.sync = true
end
use Rack::CommonLogger, LOGGER
