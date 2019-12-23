require 'test_helper'

class PostFactoryTest < ActiveSupport::TestCase
  LEAD_BREAK_SECTION1 = "{: .lead}\r\n<!–-break-–>"
  LEAD_BREAK_SECTION2 = "{: .lead}\n<!–-break-–>"
  
  setup do 
    @post_factory = Factories::PostFactory.new
  end

  test 'create_post should return nil if given a nil value for post_contents' do 
    # Act
    result = @post_factory.create_post(nil, nil, nil)

    # Assert
    assert_nil result
  end

  test 'create_post should return nil if given a non-string type for post_contents' do
    # Act
    result = @post_factory.create_post(1, 'my post.md', 'myref')

    # Assert
    assert_nil result
  end

  test 'create_post should return a post model with correct values' do 
    # Arrange
    post_contents = %(---
layout: post
title: Some Post
author: Andrew Wojciechowski
tags:
  - announcement
  - info
hero: https://source.unsplash.com/collection/145103/
overlay: green
---
#{LEAD_BREAK_SECTION1}
#An H1 tag
##An H2 tag)

    # Act
    result = @post_factory.create_post(post_contents, 'my post.md', 'myref')

    # Assert
    assert_equal 'my post.md', result.file_path
    assert_equal 'myref', result.github_ref
    assert_equal 'Some Post', result.title
    assert_equal 'Andrew Wojciechowski', result.author
    assert_equal 'announcement, info', result.tags
    assert_equal '', result.hero
    assert_equal 'green', result.overlay
    assert_equal "#An H1 tag\n##An H2 tag", result.contents
  end

  test 'create_post should return a post model with correct values given a post with \r\n line breaks' do 
    # Arrange
    post_contents = %(---
layout: post\r
title: Some Post\r
author: Andrew Wojciechowski\r
tags:\r
  - announcement\r
  - info\r
hero: https://source.unsplash.com/collection/145103/blah.com\r
overlay: green\r
---\r
#{LEAD_BREAK_SECTION2}
#An H1 tag\r
##An H2 tag)
        
    # Act
    result = @post_factory.create_post(post_contents, 'my post.md', 'myref')
        
    # Assert
    assert_equal 'my post.md', result.file_path
    assert_equal 'myref', result.github_ref
    assert_equal "Some Post\r", result.title
    assert_equal "Andrew Wojciechowski\r", result.author
    assert_equal "announcement\r, info\r", result.tags
    assert_equal "https://source.unsplash.com/collection/145103/blah.com\r", result.hero
    assert_equal "green\r", result.overlay
    assert_equal "#An H1 tag\r\n##An H2 tag", result.contents
  end
end
