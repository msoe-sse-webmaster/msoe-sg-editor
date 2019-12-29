##
# This class is responsible for creating posts on the SG website
class Services::PostCreationService < BasePostService
  def initialize
    super
  end

  ##
  # This method submits a new post to GitHub by checking out a new branch for the post,
  # if the branch already doesn't exist. Commiting and pushing the markdown and any photos 
  # attached to the post to the branch. And then finally opening a pull request into master 
  # for the new post. The SSE webmaster will be requested for review on the created pull request
  #
  # Params
  # +oauth_token+::a user's oauth access token
  # +post_markdown+:: the markdown contents of a post
  def create_post(post_markdown, post_title)
    # This ref_name variable represents the branch name
    # for creating a post. At the end we strip out all of the whitespace in 
    # the post_title to create a valid branch name
    branch_name = "createPost#{post_title.gsub(/\s+/, '')}"
    ref_name = "heads/#{branch_name}"

    master_head_sha = @github_service.get_master_head_sha
    sha_base_tree = @github_service.get_base_tree_for_branch(master_head_sha)

    @github_service.create_ref_if_necessary(ref_name, master_head_sha)
      
    new_post_path = create_new_filepath_for_post(post_title)
    new_tree_sha = create_new_tree(post_markdown, post_title, new_post_path, sha_base_tree)
      
    @github_service.commit_and_push_to_repo("Created post #{post_title}", 
                                            new_tree_sha, master_head_sha, ref_name)
    @github_service.create_pull_request(branch_name, 'master', "Created Post #{post_title}", 
                                        Rails.configuration.pull_request_body, 
                                        [Rails.configuration.webmaster_github_username])
      
    PostImageManager.instance.clear
  end

  private
    def create_new_filepath_for_post(post_title)
      "_posts/#{DateTime.now.strftime('%Y-%m-%d')}-#{post_title.gsub(/\s+/, '')}.md"
    end
end
