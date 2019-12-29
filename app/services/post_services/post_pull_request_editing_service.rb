class Services::PostPullRequestEditingService < BasePostService
  def initialize
    super
  end

  ##
  # This method submits changes to a post that is already in PR, commiting and pushing the markdown changes
  # and any added photos to the branch. Since the post is in PR these changes will be a PR updated to the given branch
  #
  # Params:
  # +post_markdown+::the modified markdown to submit
  # +post_title+::the title for the existing post
  # +existing_post_file_path+::the file path to the existing post on GitHub
  # +ref+::the ref to update
  def edit_post_in_pr(post_markdown, post_title, existing_post_file_path, ref)
    ref_name = @github_service.get_ref_name_by_sha(ref)
    sha_base_tree = @github_service.get_base_tree_for_branch(ref)

    new_tree_sha = create_new_tree(post_markdown, post_title, existing_post_file_path, sha_base_tree)
    @github_service.commit_and_push_to_repo("Edited post #{post_title}", new_tree_sha, ref, ref_name)
      
    PostImageManager.instance.clear
  end
end
