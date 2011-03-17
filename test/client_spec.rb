require File.dirname(__FILE__) + '/support'

describe "Duostack client" do
  
  before(:all) do
    # set which client to use (allows testing of gem installed client)
    # uses client in src/ by default
    $client_executable = ENV['DSCLIENT'] || "#{File.dirname(__FILE__)}/../src/duostack"
    $client = File.basename($client_executable)
    
    # swap out current credentials so we can test validation of test account credentials
    # TODO: make this more robust and less interfering by using --creds flag
    `mv ~/.duostack ~/.duostack.bak`
    
    # generate a test app name off of current timestamp
    @app_name = "test#{Time.now.to_i}"
    @app_path = "/tmp/duostack/#{@app_name}"
  end
  
  describe "general commands" do
    
    it "displays help" do
      run_command("").should =~ /Usage/
      run_command("help").should =~ /Usage/
    end
    
    it "displays version number" do
      run_command("version").should =~ /\A\d+\.\d+\.\d+\Z/
    end
  end
  
  
  describe "user commands" do
    
    before(:all) do
      
      # make directory, copy template app, and initialize a git repo for test app
      `mkdir -p #{@app_path}`
      `cp -r #{File.dirname(__FILE__)}/templates/rack/* #{@app_path}`
      `cd #{@app_path} && git init && git add . && git commit -m "Initial commit."`
    end
    
    it "should reject invalid credentials" do
      user = pass = ' '
      
      result = `expect #{File.dirname(__FILE__)}/credentials_test.expect #{$client_executable} "#{user}" "#{pass}" 2>/dev/null`.gsub("\r", '')
      expected = <<-END.gsub(/^ {8}/, '').gsub("\r", '')
        spawn #{$client_executable} sync#{' ' if windows?}
        First-time Duostack client setup
        Email: #{user}
        Password: 
        #{$client}: authentication error, please try again or contact support@duostack.com
      END
      result.should == expected
    end
    
    it "should sync credentials" do
      user, pass = ENV['DSUSER'], ENV['DSPASS']
      raise "pass DSUSER and DSPASS for credentials sync test" if user.to_s.empty? || pass.to_s.empty?
      
      result = `expect #{File.dirname(__FILE__)}/credentials_test.expect #{$client_executable} "#{user}" "#{pass}" 2>/dev/null`.gsub("\r", '')
      expected = <<-END.gsub(/^ {8}/, '').gsub("\r", '')
        spawn #{$client_executable} sync#{' ' if windows?}
        First-time Duostack client setup
        Email: #{user}
        Password: 
        Completed initial setup... waiting for sync...
        
      END
      result.should == expected
    end
    
    it "should show a blank app list" do
      pending "test user account"
    end
    
    it "should disallow special characters in app names" do
      run_command("create illegal-name", @app_path).should match("invalid app name")
    end
    
    it "should allow app creation" do
      result = run_command("create #{@app_name}", @app_path)
      result.should match("App created")
      result.should match("Git remote added")
    end
    
    it "should disallow creation of duplicate apps" do
      # temporarily remove git remote to fool duostack create
      `cd #{@app_path} && git remote rm duostack 2>&1`
      
      # attempt re-create
      run_command("create #{@app_name}", @app_path).should match("app name already in use")
      
      # replace git remote
      `cd #{@app_path} && git remote add duostack git@duostack.net:#{@app_name}.git 2>&1`
    end
    
    it "should list apps with created app" do
      result = run_command("list")
      result.split("\n").length.should > 0
      result.split("\n").include?(@app_name)
    end
    
    it "should allow creation of another app in same folder with --remote" do
      run_command("create #{@app_name.next}", @app_path).should match("there is already a Git remote")
      
      result = run_command("create #{@app_name.next} --remote staging", @app_path)
      result.should match("App created")
      result.should match("Git remote added")
    end
    
    
    describe "app commands" do
      
      it "should accept a git push" do
        result = `cd #{@app_path} && git push duostack master 2>&1`
        result.should match("App successfully deployed to")
        result.should match("http://#{@app_name}.duostack.net")
      end
      
      it "should restart an app" do
        result = run_command("restart --app #{@app_name}")
        result.should match("App restarted")
        result.should_not match("Unable to restart app")
      end
      
      it "should retrieve app info" do
        result = run_command("info --app #{@app_name}")
        result.should match('App Name')
        result.should match(@app_name)
        result.should match('Git')
        result.should match('Stack')
      end
      
      it "should retrieve logs" do
        run_command("logs --app #{@app_name}").should match('==>')
      end
      
      it "should retrieve process list" do
        run_command("ps --app #{@app_name}").should match('Instance ID')
      end
      
      describe "commands using app/remote flag" do
        
        it "should allow specification of the app with the app flag" do
          result = `cd /tmp && #{build_command("ps --app #{@app_name}")}`.chomp
          result.should match("Instance")
        end
        
        it "should reject non-existant remote name and select real duostack remote" do
          result = run_command("ps --remote nonexistent", @app_path)
          result.should match("duostack: remote 'nonexistent' does not refer to Duostack, using remote 'duostack' instead")
          result.should match("Instance")
        end
        
        it "should reject non-duostack remote name and select real duostack remote" do
          # first add non-duostack remote
          `cd #{@app_path} && git remote add github git@github.com:duostack/duostack-client.git 2>&1`
          
          result = run_command("ps --remote github", @app_path)
          result.should match("duostack: remote 'github' does not refer to Duostack, using remote 'duostack' instead")
          result.should match("Instance")
        end
        
        it "should allow using --remote to set alternate app" do
          run_command("info --remote staging", @app_path).should match(@app_name.next)
        end
      end
      
      
      describe "config commands" do
        
        it "should list configs" do
          run_command("config --app #{@app_name}").should match("stack: autodetect")
        end
      
        it "should list config options for stack" do
          result = run_command("config stack --app #{@app_name}")
          result.should match("autodetect")
          result.should match("ruby-mri-1.9.2")
        end
      
        it "should allow setting config option for stack" do
          result = run_command("config stack ruby-mri-1.9.2 --app #{@app_name}")
          result.should match("App will be migrated to ruby-mri-1.9.2 during next Git push.")
        end
      
        it "should reflect stack change upon re-push" do
          `cd #{@app_path} && touch poke && git add poke && git commit -m "poke" && git push duostack master 2>&1`
          result = expect_console("IO.popen('ruby -v') { |f| puts f.gets }", @app_name)
          expected = <<-END.gsub(/^ {12}/, '').gsub("\r", '')
            spawn #{$client_executable} console --app #{@app_name}#{' ' if windows?}
            Connecting to Ruby console for #{@app_name}...
            >> IO.popen('ruby -v') { |f| puts f.gets }
            ruby 1.9.2p136 (2010-12-25 revision 30365) [x86_64-linux]
            => nil
            >> exit
            Connection to duostack.net closed.
          END
        
          result.should == expected
        end
        
        it "should reject invalid config names" do
          run_command("config oiwejfjasd --app #{@app_name}").should match("invalid config option name")
        end
        
        it "should reject invalid config values" do
          run_command("config stack woqreinkdv --app #{@app_name}").should match("invalid config option value")
        end
      
      end      
      
      describe "environment variables" do
      
        it "should allow adding env vars" do
          run_command("env add env1=var1 --app #{@app_name}").should match('env1 => var1')
        end
      
        it "should allow adding multiple env vars at once" do
          result = run_command("env add env2=var2 env3=var3 --app #{@app_name}")
          result.should match('env2 => var2')
          result.should match('env3 => var3')
        end
      
        it "should allow adding quoted env vars" do
          run_command("env add env4='multi word string' --app #{@app_name}").should match('env4 => multi word string')
        end
      
        it "should allow adding env vars containing single/double quotes" do
          run_command(%Q(env add env5='"double quoted"' --app #{@app_name})).should match(%Q(env5 => "double quoted"))
          run_command(%Q(env add env6="'single quoted'" --app #{@app_name})).should match(%Q(env6 => 'single quoted'))
        end
      
        it "should list env vars" do
          result = run_command("env --long --app #{@app_name}")
          result.should == run_command("env list --app #{@app_name}")
          result.should match('env1 => var1')
          result.should match('env2 => var2')
          result.should match('env3 => var3')
          result.should match('env4 => multi word string')
          result.should match('env5 => "double quoted"')
          result.should match("env6 => 'single quoted'")
        end
        
        it "should reject any additional arguments on list and clear" do
          run_command("env list  foo --app #{@app_name}").should match("unrecognized argument")
          run_command("env clear foo --app #{@app_name}").should match("unrecognized argument")
        end
        
        it "should see env vars in console" do
          run_command("restart --app #{@app_name}") # need to restart first
          result = expect_console("ENV['env1']", @app_name)
          expected = <<-END.gsub(/^ {12}/, '').gsub("\r", '')
            spawn #{$client_executable} console --app #{@app_name}#{' ' if windows?}
            Connecting to Ruby console for #{@app_name}...
            >> ENV['env1']
            => "var1"
            >> exit
            Connection to duostack.net closed.
          END
        
          result.should == expected
        end
      
        it "should allow removing env vars" do
          run_command("env remove env1 --app #{@app_name}").should == "Environment variable(s) removed"
          run_command("env --app #{@app_name}").should_not match('env1')
        end

        it "should allow removing multiple env vars at once" do
          run_command("env remove env2 env3 --app #{@app_name}").should == "Environment variable(s) removed"
        
          list = run_command("env --app #{@app_name}")
          list.should_not match('env2')
          list.should_not match('env3')
        end
      
        it "should require confirmation to clear env vars" do
          run_command("env clear --app #{@app_name}").should match("command requires confirmation")
        end
      
        it "should clear env vars" do
          run_command("env clear --app #{@app_name} --confirm").should match("Environment variables cleared")
          list = run_command("env --app #{@app_name}")
          list.should be_empty
        end
      end
      
      
      describe "collaborator access" do
      
        it "should allow adding collaborators" do
          result = run_command("access add test@example.com --app #{@app_name}")
          result.should match('Granting access for:')
          result.should match('test@example.com')
        end
      
        it "should allow adding multiple collaborators at once" do
          result = run_command("access add test@example.org test@example.net --app #{@app_name}")
          result.should match('Granting access for:')
          result.should match('test@example.net')
          result.should match('test@example.org')
        end
      
        it "should list collaborators" do
          result = run_command("access --app #{@app_name}")
          result.should == run_command("access list --app #{@app_name}")
          result.should match('test@example.com')
          result.should match('test@example.net')
          result.should match('test@example.org')
        end
      end
      
      
      describe "custom domains" do
      
        it "should allow adding custom domains" do
          domain = ENV['DSDOMAIN']
          raise "pass DSDOMAIN for custom domains tests" if domain.to_s.empty?
          
          result = run_command("domains add #{ENV['DSDOMAIN']} --app #{@app_name}")
          result.should match('Adding domain names')
          result.should match(ENV['DSDOMAIN'])
          result.should_not match('Invalid domain name')
          result.should_not match('Already in use')
          result.should_not match('Failed record check')
        end
        
        it "should not allow adding duplicate custom domains" do
          result = run_command("domains add #{ENV['DSDOMAIN']} --app #{@app_name}")
          result.should match('Already in use')
        end
      
        it "should list custom domains" do
          result = run_command("domains --app #{@app_name}")
          result.should == run_command("domains list --app #{@app_name}")
          result.should match(ENV['DSDOMAIN'])
        end
      
        it "should see be able to access the app via custom domains" do
          # perform an HTTP request to a known endpoint in the app with a known expected response
          result = `curl -s http://#{ENV['DSDOMAIN']}/ 2>&1`
          result.should match('Hello world!')
        end
      
        it "should allow removing custom domains" do
          run_command("domains remove #{ENV['DSDOMAIN']} --app #{@app_name}").should == "Domain name(s) removed"
          run_command("domains --app #{@app_name}").should_not match(ENV['DSDOMAIN'])
        end
      end
      
      
      describe "setting instances" do
        it "should show current instances" do
          result = run_command("instances --app #{@app_name}")
          result.should == run_command("instances show --app #{@app_name}")
          result.should match("1")
        end
        
        it "should reset billing confirmation flag" do
          run_command('billing_reset')
        end
        
        it "should prompt for billing confirmation" do
          # disallow billing
          result = expect_billing_confirmation('no', @app_name)
          expected = <<-END.gsub(/^ {12}/, '').gsub("\r", '')
            spawn #{$client_executable} instances 1 --app #{@app_name}#{' ' if windows?}
            This is your first time enabling a paid feature that will be billed to your account. Type 'yes' to proceed: no
          END
          result.should == expected
        end
        
        it "should re-prompt for billing confirmation after negative response" do
          # non-response
          result = expect_billing_confirmation('', @app_name)
          expected = <<-END.gsub(/^ {12}/, '').gsub("\r", '')
            spawn #{$client_executable} instances 1 --app #{@app_name}#{' ' if windows?}
            This is your first time enabling a paid feature that will be billed to your account. Type 'yes' to proceed: 
          END
          result.should == expected
        end
        
        it "should re-prompt for billing confirmation after blank response" do
          # allow billing
          result = expect_billing_confirmation('yes', @app_name)
          expected = <<-END.gsub(/^ {12}/, '').gsub("\r", '')
            spawn #{$client_executable} instances 1 --app #{@app_name}#{' ' if windows?}
            This is your first time enabling a paid feature that will be billed to your account. Type 'yes' to proceed: yes
            1
          END
          result.should == expected
        end
        
        it "should allow incrementing instances" do
          run_command("instances +1 --app #{@app_name}").should match("2")
          run_command("instances +2 --app #{@app_name}").should match("4")
        end
        
        it "should allow decrementing instances" do
          run_command("instances -1 --app #{@app_name}").should match("3")
          run_command("instances -2 --app #{@app_name}").should match("1")
        end
        
        it "should allow setting instances absolutely" do
          run_command("instances 4 --app #{@app_name}").should match("4")
          run_command("instances 2 --app #{@app_name}").should match("2")
        end
        
        it "should disallow setting instances below valid instance count" do
          run_command("instances  0 --app #{@app_name}").should match("app must have at least one instance")
          run_command("instances -2 --app #{@app_name}").should match("app must have at least one instance")
          run_command("instances -4 --app #{@app_name}").should match("app must have at least one instance")
        end
        
        it "should disallow setting instances above valid instance count" do
          run_command("instances  16 --app #{@app_name}").should match("cannot exceed instance limit")
          run_command("instances 116 --app #{@app_name}").should match("cannot exceed instance limit")
          run_command("instances +14 --app #{@app_name}").should match("cannot exceed instance limit")
        end
        
        # TODO: check 'ps' to make sure instances started/stopped
        # TODO: check account verification process (currently tests need to run with verified account)
      end
      
      
      describe "for Ruby apps" do
        it "should start a console session" do
          result = expect_console("puts 'console test'", @app_name)
          expected = <<-END.gsub(/^ {12}/, '').gsub("\r", '')
            spawn #{$client_executable} console --app #{@app_name}#{' ' if windows?}
            Connecting to Ruby console for #{@app_name}...
            >> puts 'console test'
            console test
            => nil
            >> exit
            Connection to duostack.net closed.
          END
          
          result.should == expected
        end
        
        it "should run rake tasks" do
          run_command("rake -T --app #{@app_name}").should match('rake about')
        end
      end
    end
  
  end
  
  
  describe "cleanup commands" do
    it "should allow app deletion" do
      result = run_command("destroy --app #{@app_name} --confirm", @app_path)
      result.should match("App destroyed")
    end
    
    it "should not have deleted app in list" do
      run_command("list").should_not match(@app_name)
    end
    
    it "should clean up duostack git remote" do
      result = `cd #{@app_path} && git remote`.chomp
      result.should_not include('duostack')
    end
  end
  
  after(:all) do
    # swap credentials back
    `mv ~/.duostack.bak ~/.duostack`
  end
  
end