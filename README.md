# Setup
1. You will need Ruby installed on your development machine. Ruby 2.4 or 2.5 should both work fine. 
    - Check version with `ruby -v`
2. Install the most recent version of yarn from [here](https://yarnpkg.com/lang/en/docs/install/#windows-stable)
3. Install the most recent ImageMagick binary from [here](http://www.imagemagick.org/script/download.php#windows)
4. Clone the repository and navigate to your project directory in cmd, git bash
5. Run `gem install bundler`
6. Run `bundle install`
7. At this point you should be able to run the post editor application locally by running `rails server` and navigating to http://localhost:3000 in a brower.
# Continuous Integration
There are checks that will be performed whenever Pull Requests are opened. To save time on the build server, please run the tests locally to check for errors that will occur in the CI builds.
1. To run all tests, run the command `rake`
    - To run tests in an individual file run the command `rails test <path_to_test_file>`
2. To run rubocop, run the command `bundle exec rubocop`