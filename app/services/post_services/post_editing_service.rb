module Services
  ##
  # This class is responsible for editing posts on the SG website
  class PostEditingService < BasePostService
    def initialize
      super
    end

    ##
    # This method submits changes to an existing post to GitHub by checking out a new branch for the post,
    # if the branch already doesn't exist. Commiting and pushing the markdown changes and any added photos
    # for the existing post to the branch. And the finally opening a pull request into master for the new post.
    # The SSE webmaster will be requested for review on the created pull request
    #
    # Params
    # +post_markdown+::the modified markdown to submit
    # +post_title+::the title for the existing post
    # +existing_post_file_path+::the file path to the existing post on GitHub
    def edit_post(post_markdown, post_title, existing_post_file_path)
      # This ref_name variable represents the branch name
      # for editing a post. At the end we strip out all of the whitespace in 
      # the post_title to create a valid branch name
      branch_name = "editPost#{post_title.gsub(/\s+/, '')}"
      ref_name = "heads/#{branch_name}"

      master_head_sha = @github_service.get_master_head_sha
      sha_base_tree = @github_service.get_base_tree_for_branch(master_head_sha)

      @github_service.create_ref_if_necessary(ref_name, master_head_sha)
      new_tree_sha = create_new_tree(post_markdown, post_title, existing_post_file_path, sha_base_tree)

      @github_service.commit_and_push_to_repo("Edited post #{post_title}", new_tree_sha, master_head_sha, ref_name)
      @github_service.create_pull_request(branch_name, 'master', "Edited Post #{post_title}", 
                                          Rails.configuration.pull_request_body, 
                                          [Rails.configuration.webmaster_github_username])
        
      PostImageManager.instance.clear
    end
  end
end
