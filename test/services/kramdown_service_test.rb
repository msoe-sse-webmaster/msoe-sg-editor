require 'test_helper'
require 'mocha/setup'

class KramdownServiceTest < ActiveSupport::TestCase
  LEAD_BREAK_SECTION = "{: .lead}\r\n<!–-break-–>"
  
  setup do 
    @kramdown_service = Services::KramdownService.new
  end

  test 'get_preview should convert markdown to html' do
    # Arrange
    markdown = %(#Andy is cool
Andy is nice)

    # Act
    result = @kramdown_service.get_preview(markdown)

    # Assert
    assert_not_nil result
  end
  
  test 'get_preview should not update the src atribute of image tags 
        if no uploader or PostImage exists in PostImageManager' do 
    # Arrange
    mock_uploader = create_mock_uploader('preview_no image.png', 'my cache', nil)
    preview_uploader = create_preview_uploader('no image.png', mock_uploader)
    post_image = create_post_image('no image2.png', 'contents')

    PostImageManager.instance.expects(:uploaders).returns([ preview_uploader ])
    PostImageManager.instance.expects(:downloaded_images).returns([ post_image ])

    markdown = '![20170610130401_1.jpg](/assets/img/20170610130401_1.jpg)'

    # Act
    result = @kramdown_service.get_preview(markdown)

    # Assert
    assert_equal "<p><img src=\"/assets/img/20170610130401_1.jpg\" alt=\"20170610130401_1.jpg\" /></p>\n", result
  end

  test 'get_preview should update the src attribute of image tags if an uploader exists in PostImageManager' do 
    # Arrange
    mock_uploader = create_mock_uploader('preview_20170610130401_1.jpg', 'my cache/preview_20170610130401_1.jpg', nil)
    preview_uploader = create_preview_uploader('20170610130401_1.jpg', mock_uploader)
    post_image = create_post_image('assets/img/20170610130401_1.jpg', 'contents')

    PostImageManager.instance.expects(:uploaders).returns([ preview_uploader ])
    PostImageManager.instance.expects(:downloaded_images).returns([ post_image ]).never

    markdown = '![My Alt Text](/assets/img/20170610130401_1.jpg)'
    expected_html = "<p><img src=\"/uploads/tmp/my cache/preview_20170610130401_1.jpg\" alt=\"My Alt Text\" /></p>\n"

    # Act
    result = @kramdown_service.get_preview(markdown)

    # Assert
    assert_equal expected_html, result
  end

  test 'get_preview should update the src attribute of image tags if a PostImage exists in PostImageManager' do 
    # Arrange
    post_image = create_post_image('assets/img/20170610130401_1.jpg', 'contents')
    markdown = '![My Alt Text](/assets/img/20170610130401_1.jpg)'
    expected_html = "<p><img src=\"data:image/jpg;base64,contents\" alt=\"My Alt Text\" /></p>\n"

    PostImageManager.instance.expects(:uploaders).returns([])
    PostImageManager.instance.expects(:downloaded_images).returns([ post_image ])

    # Act
    result = @kramdown_service.get_preview(markdown)

    # Assert
    assert_equal expected_html, result
  end

  test 'get_preview should update the src attribute of images tags if an uploader 
        with a formatted filename exists in PostImageManager' do 
    # Arrange
    mock_uploader = create_mock_uploader('preview_My_File.jpg', 'my cache/preview_My_File.jpg', nil)
    preview_uploader = create_preview_uploader('My_File.jpg', mock_uploader)

    PostImageManager.instance.expects(:uploaders).returns([ preview_uploader ])

    markdown = '![My Alt Text](/assets/img/My File.jpg)'
    expected_html = "<p><img src=\"/uploads/tmp/my cache/preview_My_File.jpg\" alt=\"My Alt Text\" /></p>\n"

    # Act
    result = @kramdown_service.get_preview(markdown)

    # Assert
    assert_equal expected_html, result
  end

  test 'get_image_filename_from_markdown should return nil if the markdown doesnt 
        include an image with a given filename' do 
    # Arrange
    markdown = '![My Alt Text](/assets/img/20170610130401_1.jpg)'

    # Act
    result = @kramdown_service.get_image_filename_from_markdown('my file.jpg', markdown)

    # Assert
    assert_not result
  end

  test 'get_image_filename_from_markdown should return a filename if the markdown does 
        include an image with a given filename' do 
    # Arrange
    markdown = '![My Alt Text](/assets/img/20170610130401_1.jpg)'

    # Act
    result = @kramdown_service.get_image_filename_from_markdown('20170610130401_1.jpg', markdown)

    # Assert
    assert_equal '20170610130401_1.jpg', result
  end

  test 'get_image_filename_from_markdown should return true if the markdown does include an image with a given filename 
        and the filename has been formatted by CarrierWave' do 
    # Arrange
    markdown = '![My Alt Text](/assets/img/My File.jpg)'

    # Act
    result = @kramdown_service.get_image_filename_from_markdown('My_File.jpg', markdown)

    # Assert
    assert_equal 'My File.jpg', result
  end

  test 'get_all_image_paths should return all image paths given some markdown' do 
    # Arrange
    markdown = "![My Alt Text](/assets/img/My File.jpg)\r\n![My Alt Text](/assets/img/My File2.jpg)"

    # Act
    result = @kramdown_service.get_all_image_paths(markdown)

    # Assert
    assert_equal 2, result.length
    assert_equal 'assets/img/My File.jpg', result[0]
    assert_equal 'assets/img/My File2.jpg', result[1]
  end

  test 'get_all_images_paths should not return image paths from URIs' do 
    # Arrange
    markdown = '![My Alt Text](https://google.com/blah.jpg)'

    # Act
    result = @kramdown_service.get_all_image_paths(markdown)

    # Assert
    assert_equal 0, result.length
  end

  test 'create_jekyll_post_text should return text for a formatted post' do 
    # Arrange
    expected_post = %(---
layout: post
title: Some Post
author: Andy Wojciechowski\r
hero: https://source.unsplash.com/collection/145103/
overlay: green
published: true
---
#{LEAD_BREAK_SECTION}
# An H1 tag\r
##An H2 tag)

    # Act
    result = @kramdown_service.create_jekyll_post_text("#An H1 tag\r\n##An H2 tag", 'Andy Wojciechowski', 
                                                       'Some Post', '', 'green', '')

    # Assert
    assert_equal expected_post, result
  end

  test 'create_jekyll_post_text should return a formatted post given valid post tags' do 
    # Arrange
    expected_post = %(---
layout: post
title: Some Post
author: Andy Wojciechowski\r
tags:
  - announcement\r
  - info\r
  - hack n tell\r
hero: https://source.unsplash.com/collection/145103/
overlay: green
published: true
---
#{LEAD_BREAK_SECTION}
# An H1 tag\r
##An H2 tag)
    # Act
    result = @kramdown_service.create_jekyll_post_text("#An H1 tag\r\n##An H2 tag",
                                                       'Andy Wojciechowski', 
                                                       'Some Post', 
                                                       'announcement, info,    hack n tell     ', 
                                                       'green', '')
    # Assert
    assert_equal expected_post, result
  end

  test 'create_jekyll_post_text should add a space after the # symbols indicating a header tag' do 
    # Arrange
    expected_post = %(---
layout: post
title: Some Post
author: Andy Wojciechowski\r
hero: https://source.unsplash.com/collection/145103/
overlay: green
published: true
---
#{LEAD_BREAK_SECTION}
# H1 header\r
\r
## H2 header\r
\r
### H3 header\r
\r
#### H4 header\r
\r
##### H5 header\r
\r
###### H6 header)

    markdown_text = %(#H1 header\r
\r
##H2 header\r
\r
###H3 header\r
\r
####H4 header\r
\r
#####H5 header\r
\r
######H6 header)

    # Act
    result = @kramdown_service.create_jekyll_post_text(markdown_text, 'Andy Wojciechowski', 'Some Post', '', 'green', '')

    # Assert
    assert_equal expected_post, result
  end

  test 'create_jekyll_post_text should only add one space after a header' do 
    # Arrange
    expected_post = %(---
layout: post
title: Some Post
author: Andy Wojciechowski\r
tags:
  - announcement\r
  - info\r
hero: https://source.unsplash.com/collection/145103/
overlay: green
published: true
---
#{LEAD_BREAK_SECTION}
# An H1 tag\r
##An H2 tag)
    # Act
    result = @kramdown_service.create_jekyll_post_text("# An H1 tag\r\n##An H2 tag",
                                                       'Andy Wojciechowski', 'Some Post',
                                                       'announcement, info', 'green', '')
    # Assert
    assert_equal expected_post, result
  end

  test 'create_jekyll_post_text should substitute the given hero if its not empty' do 
    # Arrange
    expected_post = %(---
layout: post
title: Some Post
author: Andy Wojciechowski\r
tags:
  - announcement\r
  - info\r
hero: bonk
overlay: green
published: true
---
#{LEAD_BREAK_SECTION}
# An H1 tag\r
##An H2 tag)
    # Act
    result = @kramdown_service.create_jekyll_post_text("# An H1 tag\r\n##An H2 tag",
                                                       'Andy Wojciechowski', 'Some Post',
                                                       'announcement, info', 'green', 'bonk')
    # Assert
    assert_equal expected_post, result
  end

  test 'create_jekyll_post_text should add a line break before a reference style image 
        if the markdown starts with a reference style image' do 
    image_tag = "\r\n![alt text][logo]"
    markdown = "[logo]: https://ieeextreme.org/wp-content/uploads/2019/05/Xtreme_colour-e1557478323964.png#{image_tag}"

    # Arrange
    expected_post = %(---
layout: post
title: Some Post
author: Andy Wojciechowski\r
tags:
  - announcement\r
  - info\r
hero: bonk
overlay: green
published: true
---
#{LEAD_BREAK_SECTION}
\r
#{markdown})

    # Act
    result = @kramdown_service.create_jekyll_post_text(markdown, 'Andy Wojciechowski', 'Some Post', 
                                                      'announcement, info', 'green', 'bonk')

    # Assert
    assert_equal expected_post, result
  end
end
