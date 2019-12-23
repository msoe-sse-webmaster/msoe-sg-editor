require_relative '../models/post'

##
# This module is a factory for parsing post text and creating a correseponding post model
module Factories
  class PostFactory
    LEAD = '{: .lead}'
    BREAK = '<!–-break-–>'

    ##
    # This method parses markdown in a post a returns a post model
    # 
    # Params:
    # +post_contents+::markdown in a given post
    # +file_path+::the path on GitHub to the post
    # +ref+::a sha for a ref indicating the head of a branch a post is pushed to on the GitHub server
    def create_post(post_contents, file_path, ref)      
      return create_post_model(post_contents, file_path, ref) if !post_contents.nil? && post_contents.is_a?(String)
    end

  private
    def parse_tags(header)
      result = []
      header.lines.each do |line|
        tag_match = line.match(/\s*-\s*(.*)/)
        result << tag_match.captures.first if tag_match
      end
      result.join(', ')
    end

    def create_post_model(post_contents, file_path, ref)
      result = Post.new

      result.file_path = file_path
      result.github_ref = ref

      # What this regular expression does is it matches three groups
      # The first group represents the header of the post which appears
      # between the two --- lines. The second group is for helping capture newline characters
      # correctly and the third group is the actual post contents
      match_obj = post_contents.match(/---(.*)---(\r\n|\r|\n)(.*)/m)
      header = match_obj.captures[0]
      
      parse_post_header(header, result)
      result.contents = match_obj.captures[2]
                                 .remove("#{LEAD}\r\n")
                                 .remove("#{LEAD}\n")
                                 .remove("#{BREAK}\r\n")
                                 .remove("#{BREAK}\n")
      result.tags = parse_tags(header)
      result
    end

    def parse_post_header(header, post_model)
      # The following regular expressions in this method look for specific properities
      # located in the post header.
      post_model.title = header.match(/title:\s*(.*)(\r\n|\r|\n)/).captures.first
      post_model.author = header.match(/author:\s*(.*)(\r\n|\r|\n)/).captures.first
      post_model.hero = header.match(/hero:\s*(.*)(\r\n|\r|\n)/).captures.first
      post_model.hero = '' if post_model.hero == Rails.configuration.default_hero
      post_model.overlay = header.match(/overlay:\s*(.*)(\r\n|\r|\n)/).captures.first
    end
  end
end
