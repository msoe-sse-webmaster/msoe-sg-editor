module Services
  ##
  # The base class for service classes responsible for performing operations on posts
  class BasePostService
    def initialize
      @github_service = GithubService.new
      @kramdown_service = KramdownService.new
    end

    protected
      def create_new_tree(post_markdown, post_title, post_file_path, sha_base_tree)
        file_information = [ create_blob_for_post(post_markdown, post_title, post_file_path) ]
        create_image_blobs(post_markdown, file_information)
        @github_service.create_new_tree_with_blobs(file_information, sha_base_tree)
      end

    private
      def create_blob_for_post(post_markdown, post_title, post_file_path)
        blob_sha = @github_service.create_text_blob(post_markdown)
        { path: post_file_path, blob_sha: blob_sha }
      end

      def create_image_blobs(post_markdown, current_file_information)
        PostImageManager.instance.uploaders.each do |uploader|
          # This check prevents against images that have been removed from the markdown
          markdown_file_name = @kramdown_service.get_image_filename_from_markdown(uploader.filename, post_markdown)
          if markdown_file_name
            # This line uses .file.file since the first .file returns a carrierware object
            File.open(uploader.post_image.file.file, 'rb') do |file|
              base_64_encoded_image = Base64.encode64(file.read)
              image_blob_sha = @github_service.create_base64_encoded_blob(base_64_encoded_image)
              current_file_information << { path: "assets/img/#{markdown_file_name}", blob_sha: image_blob_sha }
            end
          end
        end
      end
  end
end
