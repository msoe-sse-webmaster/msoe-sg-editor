require 'octokit'
require 'base64'
require 'date'
require 'cgi'

##
# This module contains all operations involving interacting with the GitHub API
module Services
  class GithubService
    USERNAME = ENV['GH_SERVICE_ACCOUNT_USERNAME']
    PASSWORD = ENV['GH_SERVICE_ACCOUNT_PASSWORD']

    ##
    # This method fetches all the markdown contents of all the posts on the SG website
    # that have been written and returns a list of models representing a Post.
    def get_all_posts
      result = []
      client = create_octokit_client
      posts = client.contents(full_repo_name, path: '_posts')
      posts.each do |post|
        post_api_response = client.contents(full_repo_name, path: post.path)

        post_model = create_post_from_api_response(post_api_response, nil)
        image_paths = KramdownService.get_all_image_paths(post_model.contents)

        images = []
        image_paths.each do | image_path |
          image_content = client.contents(full_repo_name, path: image_path)
          images << create_post_image(image_path, image_content.content)
        end

        post_model.images = images
        
        result << post_model
      end
      result
    end

    ##
    # This method fetches all of the posts that have been written but have not been merged into master yet.
    def get_all_posts_in_pr
      result = []
      client = create_octokit_client
      pull_requests_for_user = get_open_post_editor_pull_requests
      
      pull_requests_for_user.each do | pull_request |
        pull_request_files = client.pull_request_files(full_repo_name, pull_request[:number])

        post = nil
        images = []
        pull_request_files.each do | pull_request_file |
          contents_url_params = CGI.parse(pull_request_file[:contents_url])

          # The CGI.parse method returns a hash with the key being the URL and the value being an array of
          # URI parameters so in order to get the ref we need to grab the first value in the hash and the first
          # URI parameter in the first hash value
          ref = contents_url_params.values.first.first
          file_contents = client.contents(full_repo_name, path: pull_request_file[:filename], ref: ref)

          if pull_request_file[:filename].ends_with?('.md')
            post = create_post_from_api_response(file_contents, ref)
            result << post
          else
            images << create_post_image(pull_request_file[:filename], file_contents.content)
          end
        end

        post.images = images
      end
      result
    end
    
    ##
    # This method fetches a single post from the SG website given a post title
    # and returns a Post model
    # 
    # Params:
    # +title+:: A title of a SSE website post
    # +ref+::a sha for a ref indicating the head of a branch a post is pushed to on the GitHub server
    def get_post_by_title(title, ref)
      result = nil
      result = get_all_posts_in_pr_for_user.find { |x| x.title == title } if ref
      result = get_all_posts.find { |x| x.title == title } if !ref
      result.images.each { |x| PostImageManager.instance.add_downloaded_image(x) } if result
      result
    end

    ##
    # This method gets the sha of the commit at the head of master in the SG website repo
    def get_master_head_sha
      client = create_octokit_client
      client.ref(full_repo_name, 'heads/master')[:object][:sha]
    end

    ##
    # This method gets the sha of the base tree for a given branch in the SG website repo
    #
    # Params
    # +head_sha+::the sha of the head of a certain branch
    def get_base_tree_for_branch(head_sha)
      client = create_octokit_client
      client.commit(full_repo_name, head_sha)[:commit][:tree][:sha]
    end

    ##
    # This method create a new blob in the SG website repo with text content
    #
    # Params
    # +text+::the text content to create a blob for
    def create_text_blob(text)
      client = create_octokit_client
      client.create_blob(full_repo_name, text)
    end

    ##
    # This method creates a new blob in the SG website repo with base 64 encoded content
    #
    # Params
    # +content+::the base 64 encoded content to create a blob for
    def create_base64_encoded_blob(content)
      client = create_octokit_client
      client.create_blob(full_repo_name, content, 'base64')
    end

    ##
    # This method creates a new tree in the SG website repo and returns the tree's sha.
    # The method assumes that the paths passed into the method have corresponding blobs
    # created for the files
    #
    # Params:
    # +file_information+::an array of hashes containing the file path and the blob sha for a file
    # +sha_base_tree+::the sha of the base tree
    def create_new_tree_with_blobs(file_information, sha_base_tree)
      client = create_octokit_client
      blob_information = []
      file_information.each do |file|
        # This mode property on this hash represents the file mode for a GitHub tree. 
        # The mode is 100644 for a file blob. See https://developer.github.com/v3/git/trees/ for more information
        blob_information << { path: file[:path],
                              mode: '100644',
                              type: 'blob',
                              sha: file[:blob_sha] }
      end
      client.create_tree(full_repo_name, blob_information, base_tree: sha_base_tree)[:sha]
    end

    ##
    # This method commits and pushes a tree to the SSE website repo
    #
    # Params:
    # +commit_message+::the message for the new commit
    # +tree_sha+::the sha of the tree to commit
    # +head_sha+::the sha of the head to commit from
    def commit_and_push_to_repo(commit_message, tree_sha, head_sha, ref_name)
      client = create_octokit_client
      sha_new_commit = client.create_commit(full_repo_name, commit_message, tree_sha, head_sha)[:sha]
      client.update_ref(full_repo_name, ref_name, sha_new_commit)
    end

    ##
    # This method creates a pull request for a branch in the SG website repo
    #
    # Params:
    # +source_branch+::the source branch for the PR
    # +base_branch+::the base branch for the PR
    # +pr_title+::the title for the PR
    # +pr_body+::the body for the PR
    # +reviewers+::an array of pull request reviewers for the PR
    def create_pull_request(source_branch, base_branch, pr_title, pr_body, reviewers)
      client = create_octokit_client
      pull_number = client.create_pull_request(full_repo_name, base_branch, source_branch, pr_title, pr_body)[:number]
      client.request_pull_request_review(full_repo_name, pull_number, reviewers: reviewers)
    end

    ##
    # This method will create a branch in the SG website repo
    # if it already doesn't exist
    #
    # Params:
    # +ref_name+:: the name of the branch to create if necessary
    # +master_head_sha+:: the sha representing the head of master
    def create_ref_if_necessary(ref_name, master_head_sha)
      client = create_octokit_client
      client.ref(full_repo_name, ref_name)
      rescue Octokit::NotFound
        client.create_ref(full_repo_name, ref_name, master_head_sha)
    end

    ##
    # This method will fetch a GitHub's ref name given it's sha identifier.
    # It will also strip off the starting refs portion of the name
    #
    # Params:
    # +oauth_token+::a user's oauth access token
    # +ref_sha+:: the sha of the ref to fetch
    def get_ref_name_by_sha(ref_sha)
      client = create_octokit_client
      ref_response = client.refs(full_repo_name).find { |x| x[:object][:sha] == ref_sha }
      ref_response[:ref].match(/refs\/(.*)/).captures.first
    end

    private
      def full_repo_name
        "#{Rails.configuration.github_org}/#{Rails.configuration.github_repo_name}"
      end

      def create_post_from_api_response(post, ref)
        # Base64.decode64 will convert our string into a ASCII string
        # calling force_encoding('UTF-8') will fix that problem
        text_contents = Base64.decode64(post.content).force_encoding('UTF-8')
        PostFactory.create_post(text_contents, post.path, ref)
      end

      def get_open_post_editor_pull_requests
        client = create_octokit_client
        open_pull_requests = client.pull_requests(full_repo_name, state: 'open')
        open_pull_requests.select { |x| x[:body] == Rails.configuration.pull_request_body}
      end

      def create_post_image(filename, contents)
        result = PostImage.new
        result.filename = filename
        result.contents = contents
        result
      end

      def create_octokit_client
        Octokit::Client.new(login: USERNAME, password: PASSWORD)
      end
  end
end
