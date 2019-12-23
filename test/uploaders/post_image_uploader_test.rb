require 'test_helper'

class PostImageUploaderTest < ActiveSupport::TestCase
  test 'PostImageUploader should only support images' do 
    # Arrange
    uploader = PostImageUploader.new

    # Act
    result = uploader.extension_whitelist

    # Assert
    assert_equal ['jpg', 'jpeg', 'gif', 'png'], result
  end

  test 'PostImageUploader should limit files to an appropriate size' do 
    # Arrange
    uploader = PostImageUploader.new

    # Act
    result = uploader.size_range

    # Assert
    assert_equal 1..5.megabytes, result
  end
end
