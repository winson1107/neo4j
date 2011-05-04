Given /^Neo4j Server is (not )?running$/ do |negate|
  if (current_platform.unix?)
    puts `#{neo4j.home}/bin/neo4j status`
    $? == (negate == 'not ' ? 256 : 0)
  elsif (current_platform.windows?)
    puts `#{neo4j.home}\\bin\\wrapper-windows-x86-32.exe -q ..\\conf\\neo4j-wrapper.conf`
    puts "result #{$?} "
    # fail "failed #{$?} " if $?!= 0
    fail "not implemented"
  else
    fail 'platform not supported'
  end

end


When /^I (start|stop) Neo4j Server$/ do |action|
  puts "=====> stop/start "
  if (current_platform.unix?)
    IO.popen("#{neo4j.home}/bin/neo4j #{action}", close_fds=1)
  elsif (current_platform.windows?)
    Dir.chdir("#{neo4j.home}\\bin")
    if (action == "start")
      IO.popen("Neo4j.bat install", close_fds=1)
      sleep 10
      IO.popen("Neo4j.bat start", close_fds=1)
    else
      IO.popen("Neo4j.bat stop", close_fds=1)
      sleep 10
      IO.popen("Neo4j.bat remove", close_fds=1)
    end
  else
    fail 'platform not supported'
  end
end


When /^wait for Server (started|stopped) at "([^\"]*)"$/ do |state, uri|
  i = 0
  puts "====> wait"
  while i<60 do
    puts i
    begin
      response = Net::HTTP.get_response(URI.parse(uri))
      puts response.to_s
      break if (response.code.to_i == 200) && state == "started"
    rescue Exception=>e
      puts e.to_s
      break if (state == "stopped")
    end
    sleep 5
    i += 1
  end
end


Then /^"([^"]*)" should (not)? ?provide the Neo4j REST interface$/ do |uri, negate|
  begin
    response = Net::HTTP.get_response(URI.parse(uri))
  rescue Exception=>e
    fail "REST-interface is not running #{e}" if e && negate != 'not'
  end
  fail 'REST-interface is not running' if negate == nil && response && response.code.to_i != 200
  fail 'REST-interface is running' if negate == 'not' && response && response.code.to_i == 200
end

