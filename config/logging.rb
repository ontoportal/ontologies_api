require 'logger'
class CustomLogger < Logger
  alias write <<

  def flush
    ((self.instance_variable_get :@logdev).instance_variable_get :@dev).flush
  end
end

# Setup global logging
require 'rack/logger'
# if [:development, :console, :test].include?(settings.environment)
if [:development, :console].include?(settings.environment)
  LOGGER = CustomLogger.new(STDOUT)
  LOGGER.level = Logger::DEBUG
else
  Dir.mkdir('log') unless File.exist?('log')
  log = File.new("log/#{settings.environment}.log", "a+")
  log.sync = true
  LOGGER = CustomLogger.new(log)
  LOGGER.level = Logger::INFO
  use Rack::CommonLogger, log
end
