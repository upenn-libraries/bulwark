# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
User.create!(:email => 'clemenc@upenn.edu', :password => 'testtest', :password_confirmation => 'testtest')

#a = AutomatedWorkflows::OPenn::Csv.generate_repos('0001/0001_batch.csv')
#agent = AutomatedWorkflows::Agent.new(AutomatedWorkflows::OPenn,a, AutomatedWorkflows::OPenn::Csv.config.endpoint, :steps_to_skip => ['ingest'])
#agent.proceed
#agent = AutomatedWorkflows::Agent.new(AutomatedWorkflows::IngestOnly, a, '', :steps_to_skip => AutomatedWorkflows.config[:ingest_only][:steps_to_skip])
#agent.proceed
