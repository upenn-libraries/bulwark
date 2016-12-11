# A secret token used to encrypt user_id's in the Bookmarks#export callback URL
# functionality, for example in Refworks export of Bookmarks. In Rails 4, Blacklight
# will use the application's secret key base instead.
#

# Blacklight.secret_key = '2b71e164c592c54b29387f3c782c55638913cae5b1a41d5ae715e615d0547b99e125ad66a59f164ea603589e52781c5571365a06bbda43ed8e4e58d2862b38af'

Blacklight.secret_key = ENV['BLACKLIGHT_SECRET_KEY']