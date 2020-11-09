namespace :bulwark do
  namespace :rubocop do
    desc 'Task to create .rubocop_todo.yml without overriding rules'
    task create_todo: :environment do
      system('rubocop --auto-gen-config  --auto-gen-only-exclude --exclude-limit 10000')
    end
  end
end
