# spec helper methods

def build_command(command)
  "#{$client_executable} #{command}"
end

def run_command(command, app_path='.')
  # run a command in the app_path (or current path if none provided)
  # redirect stderr to stdout so we catch any odd behavior
  `cd #{app_path} && #{build_command(command)} 2>&1`.chomp
end

def expect_console(type, prompt, command, app_name)
  `expect #{File.dirname(__FILE__)}/console_test.expect #{$client_executable} "#{type}" "#{prompt}" "#{command}" "#{app_name}"`.gsub("\r", '')
end

def expect_billing_confirmation(response, app_name)
  `expect #{File.dirname(__FILE__)}/billing_confirmation_test.expect #{$client_executable} "#{response}" #{@app_name}`.gsub("\r", '')
end

def windows?
  `uname`.chomp =~ /CYGWIN/
end

# http://stackoverflow.com/questions/1496019/suppresing-output-to-console-with-ruby
def silence_stream(stream, &block)
  require 'stringio'
  original_stream = stream
  stream = StringIO.new
  begin
    yield
  ensure
    stream = original_stream
  end
end
