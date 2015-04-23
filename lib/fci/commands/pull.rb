desc 'Download translations from Crowdin and add/update folders/articles on Freshdesk'
arg_name 'Describe arguments to pull here'
command :pull do |c|
  c.action do |global_options,options,args|
    puts "pull command ran"
  end
end

