desc 'Read from Freshdesk and upload to Crowdin'
arg_name 'Describe arguments to push here'
command :push do |c|
  c.action do |global_options,options,args|
    puts "push command ran"
  end
end

