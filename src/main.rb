#===============================================================================
# Much of the platform specific code should be called before Swing is touched.
# The useScreenMenuBar is an example of this.
require 'java'
require 'rbconfig'
require 'getoptlong'
require 'yaml'
require 'pp'

#===============================================================================
# Platform specific operations, feel free to remove or override any of these
# that don't work for your platform/application

case Config::CONFIG["host_os"]
when /darwin/i # OSX specific code
  java.lang.System.set_property("apple.laf.useScreenMenuBar", "true")
when /^win|mswin/i # Windows specific code
when /linux/i # Linux specific code
end

# End of platform specific code
#===============================================================================
$LOAD_PATH << File.expand_path(File.dirname(__FILE__))
require 'manifest'

# Set up global error handling so that it is consistantly logged or outputed
# You will probably want to replace the puts with your application's logger
def show_error_dialog_and_exit(exception, thread=nil)
  puts "Error in application"
  puts "#{exception.class} - #{exception}"
  if exception.kind_of? Exception
    puts exception.backtrace.join("\n")
  else
    # Workaround for JRuby issue #2673, getStackTrace returning an empty array
    output_stream = java.io.ByteArrayOutputStream.new
    exception.printStackTrace(java.io.PrintStream.new(output_stream))
    puts output_stream.to_string
  end

  # Your error handling code goes here
  
  # Show error dialog informing the user that there was an error
  title = "Application Error"
  message = "The application has encountered an error and must shut down."
  
  javax.swing.JOptionPane.show_message_dialog(nil, message, title, javax.swing.JOptionPane::DEFAULT_OPTION)
  java.lang.System.exit(0)
end
GlobalErrorHandler.on_error {|exception, thread| show_error_dialog_and_exit(exception, thread) }

require 'light_bar_model'
require 'ipti_configuration'

Dir.glob(File.dirname(__FILE__) + '/**/*_controller.rb').each{|f| require(f) }
Dir.glob(File.dirname(__FILE__) + '/**/*_model.rb').each{|f| require(f) }

configuration_file = nil
opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--configuration', '-c', GetoptLong::REQUIRED_ARGUMENT ]
)
opts.each do |opt, arg|
  case opt
    when '--help' then
      puts ARGV[0] + " [-h|--help] [-c|--configuration <Yaml-config-file>"
    when '--configuration' then
      configuration_file = arg 
  end
end

controller_klass = 'LightBarController'
model            = LightBarModel.new

if File.exists?(configuration_file)
  yml = YAML::load(File.open(configuration_file))
  unless yml['configuration'].nil?
    configuration    = yml['configuration']
    controller_klass = configuration.controller_klass
    model            = configuration.model
  end
end unless configuration_file.nil?

begin
  controller = eval("#{controller_klass}.instance")
  controller.open(:model => model)
  # Your application code goes here
rescue => e
  show_error_dialog_and_exit(e)
end