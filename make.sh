bundle config set --local path vendor/bundle
bundle install --without development
zip -r lambda_function.zip lambda_function.rb lib/ vendor/
