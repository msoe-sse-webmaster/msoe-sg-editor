require 'singleton'

##
# A singleton class for managing all image attachments for a post
class PostImageManager
  include Singleton
  
  attr_reader :uploaders
  attr_reader :downloaded_images

  ##
  # The constructor for PostImageManager which initializes the array of Carrierware
  # image uploaders to use when submiting a post and the array of downloaded images
  def initialize
    @uploaders = []
    @downloaded_images = []
  end

  ##
  # Adds an image to be uploaded in a SSE website post
  #
  # Params:
  # +file+:: A ActionDispatch::Http::UploadedFile object containing the file to be used in a post
  def add_file(file)
    uploader_to_add = PostImageUploader.new
    uploader_to_add.cache!(file)
    @uploaders.delete_if { |x| x.filename == file.original_filename }
    @uploaders << uploader_to_add
  end

  ##
  # Adds an image that was downloaded from the SSE website repo
  #
  # Params:
  # +downloaded_image+:: A PostImage object representing the downloaded image
  def add_downloaded_image(downloaded_image)
    @downloaded_images << downloaded_image
  end

  ##
  # Clears the manager of all currently exisiting image uploaders and delete's their cache directories.
  # Also clears the manager of all of the downloaded images
  def clear
    @uploaders.each do |uploader| 
      full_preview_path = "#{Rails.root}/public/uploads/tmp/#{uploader.preview.cache_name}"
      cache_dir = File.expand_path('..', full_preview_path)
      uploader.remove!
      Dir.delete(cache_dir)
    end

    @uploaders.clear
    @downloaded_images.clear
  end
end
