require 'test_helper'
require 'mocha/setup'

class PostImageManagerTest < ActiveSupport::TestCase
  setup do
    setup_clear_mocks
    PostImageManager.instance.clear
  end

  test 'add_file should create a new PostImageUploader and cache the file' do 
    # Arrange
    mock_file = create_mock_action_dispatch_file('my file.jpg')
    PostImageUploader.any_instance.expects(:cache!).with(mock_file).once

    # Act
    PostImageManager.instance.add_file(mock_file)

    # Assert
    assert_equal 1, PostImageManager.instance.uploaders.length
    assert PostImageManager.instance.uploaders.first.is_a?(PostImageUploader)
  end

  test 'add_file should remove any previous uploaders that have the same filename as the file being added' do 
    # Arrange
    mock_file = create_mock_action_dispatch_file('my file.jpg')
    PostImageUploader.any_instance.expects(:cache!).with(mock_file).twice
    PostImageUploader.any_instance.expects(:filename).returns('my file.jpg').at_least_once

    # Act
    PostImageManager.instance.add_file(mock_file)
    PostImageManager.instance.add_file(mock_file)

    # Assert
    assert_equal 1, PostImageManager.instance.uploaders.length
    assert PostImageManager.instance.uploaders.first.is_a?(PostImageUploader)
  end

  test 'add_downloaded_image should add a downloaded image to the donwloaded_images collection' do 
    # Arrange
    post_image = PostImage.new
    post_image.filename = 'Sample.jpg'
    post_image.contents = 'contents'

    # Act
    PostImageManager.instance.add_downloaded_image(post_image)

    # Assert
    assert_equal 1, PostImageManager.instance.downloaded_images.length
    assert PostImageManager.instance.downloaded_images.first.is_a?(PostImage)
  end

  test 'clear should clear all PostImageUploader instances from the manager' do 
    # Arrange
    mock_file = create_mock_action_dispatch_file('my file.jpg')

    PostImageUploader.any_instance.expects(:cache!).with(mock_file).once

    # Act
    PostImageManager.instance.add_file(mock_file)
    PostImageManager.instance.clear

    # Assert
    assert_equal 0, PostImageManager.instance.uploaders.length
  end

  test 'clear should clear all PostImage instances from the manager' do 
    # Arrange
    post_image = PostImage.new
    post_image.filename = 'Sample.jpg'
    post_image.contents = 'contents'
    
    # Act
    PostImageManager.instance.add_downloaded_image(post_image)
    PostImageManager.instance.clear

    # Assert
    assert_equal 0, PostImageManager.instance.downloaded_images.length
  end

  private
    def setup_clear_mocks
      mock_uploader = create_mock_uploader('preview_my file.jpg', 'my cache/preview_my file.jpg', nil)
      preview_uploader = create_preview_uploader('my file', mock_uploader)

      PostImageUploader.any_instance.expects(:preview).returns(preview_uploader).at_least(0)
      PostImageUploader.any_instance.expects(:remove!).at_least(0)
      Dir.expects(:delete).at_least(0)
    end
end
