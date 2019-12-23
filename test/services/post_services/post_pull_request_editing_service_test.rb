class PostPullRequestEditingServiceTest < ActiveSupport::TestCase
  setup do
    @post_pull_request_editing_service = Services::PostPullRequestEditingService.new
  end

  test 'edit_post_in_pr should commit edits to an existing post up to the SG website Github repo' do 
    # Arrange
    Services::GithubService.any_instance.expects(:get_ref_name_by_sha).returns('heads/createPostTestPost')
    Services::GithubService.any_instance.expects(:get_base_tree_for_branch).with('my ref').returns('master tree sha')
    Services::GithubService.any_instance.expects(:create_text_blob).with('# hello').returns('post blob sha')
    Services::GithubService.any_instance.expects(:create_new_tree_with_blobs)
                           .with([ create_file_info_hash('existing post.md', 'post blob sha')], 'master tree sha')
                           .returns('new tree sha')
    Services::GithubService.any_instance.expects(:commit_and_push_to_repo)
                           .with('Edited post TestPost', 'new tree sha', 
                                 'my ref', 'heads/createPostTestPost').once
            
    PostImageManager.instance.expects(:clear).once
                    
    # Act
    @post_pull_request_editing_service.edit_post_in_pr('# hello', 'TestPost', 'existing post.md', 'my ref')
        
    # No Assert - taken care of with mocha mock setups
  end
end