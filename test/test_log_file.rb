class TestLogFile < File
  def initialize
    super(File.expand_path("../test_run.log", __FILE__), "w")
  end
end