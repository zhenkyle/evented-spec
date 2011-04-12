require 'pathname'

module EventedSpec
  # Path to version file
  VERSION_FILE = Pathname.new(__FILE__).dirname + '/../../VERSION'
  # Gem version
  VERSION = VERSION_FILE.exist? ? VERSION_FILE.read.strip : nil
end