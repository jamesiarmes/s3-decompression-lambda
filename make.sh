bundle config set --local path vendor/bundle
bundle install
zip -r lambda_function.zip lambda_function.rb lib/ vendor/
